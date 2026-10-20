//
//  DocumentRevocationService.swift
//

import Foundation
import WalletDomainModels

/// Service responsible for checking and caching document revocation status
/// Implements background monitoring similar to EUDI reference app
public final class DocumentRevocationService: @unchecked Sendable {

    // MARK: - Configuration
    
    /// Interval between automatic status checks.
    public var checkInterval: TimeInterval = 60
    
    /// Initial delay before the first check after starting.
    public var initialDelay: TimeInterval = 5
    
    // MARK: - Private Properties
    
    private let walletController: WalletKitProtocol
    private let notificationScheduler: LocalNotificationScheduling
    private var statusCache: [String: DocumentCredentialStatus] = [:]
    private let cacheQueue = DispatchQueue(label: "com.diia.revocation.cache", attributes: .concurrent)
    
    /// Persistent storage for revoked document IDs
    private let revokedStorageKey = "com.diia.revocation.revokedDocumentIds"
    
    /// Background monitoring task
    private var monitoringTask: Task<Void, Never>?
    
    /// Last time status was checked
    private var lastCheckDate: Date?
    
    // MARK: - AsyncStream
    
    /// Stream that emits whenever document revocation status changes or a list refresh is needed.
    /// This is the single observation mechanism for revocation updates — consumers attach a `for await` loop via injection
    public var statusUpdates: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            continuationsQueue.sync(flags: .barrier) {
                statusContinuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.continuationsQueue.async(flags: .barrier) {
                    self?.statusContinuations.removeValue(forKey: id)
                }
            }
        }
    }
    
    private var statusContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private let continuationsQueue = DispatchQueue(label: "com.diia.revocation.continuations", attributes: .concurrent)
    
    public init(
        walletController: WalletKitProtocol,
        notificationScheduler: LocalNotificationScheduling
    ) {
        self.walletController = walletController
        self.notificationScheduler = notificationScheduler
        loadPersistedRevokedIds()
    }
    
    // MARK: - Background Monitoring
    
    /// Start background revocation monitoring
    /// Call this on app launch (e.g., in AppDelegate or AppRouter)
    public func startMonitoring() {
        guard monitoringTask == nil else {
            return
        }

        // Prompt for local-notification permission once so revocation banners can
        // surface while the user is on a non-Documents screen. No-op if the user
        // has already been asked.
        notificationScheduler.requestAuthorizationIfNeeded()

        monitoringTask = Task(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            // Initial delay before first check
            try? await Task.sleep(nanoseconds: UInt64(self.initialDelay * 1_000_000_000))
            
            while !Task.isCancelled {
                await self.performRevocationCheck()
                
                // Wait for next check interval
                try? await Task.sleep(nanoseconds: UInt64(self.checkInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stop background revocation monitoring
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    // MARK: - Public Query Methods
    
    /// Get cached status for a document (does not trigger network request)
    public func getCachedStatus(for documentId: String) -> DocumentCredentialStatus? {
        cacheQueue.sync {
            statusCache[documentId]
        }
    }
    
    /// Check if a document is revoked based on cached status
    public func isRevoked(documentId: String) -> Bool {
        let status = getCachedStatus(for: documentId)
        return status == .revoked || status == .suspended
    }
    
    /// Get all revoked document IDs (from cache)
    public func getRevokedDocumentIds() -> [String] {
        cacheQueue.sync {
            statusCache.filter { $0.value == .revoked || $0.value == .suspended }.map { $0.key }
        }
    }
    
    /// Get persisted revoked document IDs (survives app restart)
    public func getPersistedRevokedIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: revokedStorageKey) ?? []
    }
    
    // MARK: - Manual Check Methods
    
    /// Force an immediate status check for all documents
    @discardableResult
    public func checkAllDocumentsStatus(force: Bool = false) async -> [String: DocumentCredentialStatus] {
        // Skip if checked recently (unless forced)
        if !force {
            let snapshot = cacheQueue.sync { (lastCheck: lastCheckDate, cache: statusCache) }
            if let lastCheck = snapshot.lastCheck, Date().timeIntervalSince(lastCheck) < checkInterval {
                return snapshot.cache
            }
        }
        
        let results = await walletController.checkAllDocumentsStatus()
        updateCache(with: results)
        return results
    }
    
    /// Check status of a single document
    public func checkDocumentStatus(documentId: String) async -> DocumentCredentialStatus {
        guard let document = walletController.fetchDocument(with: documentId) else {
            return .unknown
        }
        
        let status = await walletController.checkDocumentStatus(for: document)
        updateSingleStatus(documentId: documentId, status: status)
        return status
    }
    
    /// Clear the status cache and persisted data
    public func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.statusCache.removeAll()
            self?.lastCheckDate = nil
        }
        UserDefaults.standard.removeObject(forKey: revokedStorageKey)
    }
    
}

// MARK: - Private Methods

private extension DocumentRevocationService {
    func performRevocationCheck() async {
        let documents = walletController.fetchAllDocuments()
        let previouslyRevokedIds = Set(getPersistedRevokedIds())
        
        var newlyRevokedDocuments: [String: String] = [:] // [displayName: documentId]
        var fromRevokedToValid: [String] = []
        var allResults: [String: DocumentCredentialStatus] = [:]
        
        for document in documents {
            let status = await walletController.checkDocumentStatus(for: document)
            allResults[document.id] = status
            
            let wasRevoked = previouslyRevokedIds.contains(document.id)
            let isNowRevoked = (status == .revoked || status == .suspended)
            
            if isNowRevoked && !wasRevoked {
                // Newly revoked
                newlyRevokedDocuments[document.displayName ?? document.id] = document.id
            } else if !isNowRevoked && wasRevoked {
                // Was revoked, now valid
                fromRevokedToValid.append(document.id)
            }
        }
        
        // Update cache
        updateCache(with: allResults)
        
        // Handle state transitions
        if !fromRevokedToValid.isEmpty {
            removeFromPersistedRevoked(ids: fromRevokedToValid)
        }
        
        if !newlyRevokedDocuments.isEmpty {
            addToPersistedRevoked(ids: Array(newlyRevokedDocuments.values))
            notifyDocumentsRevoked(documents: newlyRevokedDocuments)
        }
        
        // Always notify list refresh if any changes
        if !fromRevokedToValid.isEmpty || !newlyRevokedDocuments.isEmpty {
            notifyListRefresh()
        }
    }
    
    func updateCache(with results: [String: DocumentCredentialStatus]) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let previousCache = self.statusCache
            self.statusCache = results
            self.lastCheckDate = Date()

            let changed = results.contains { id, status in previousCache[id] != status }
            if changed {
                self.emitStatusUpdate()
            }
        }
    }
    
    func updateSingleStatus(documentId: String, status: DocumentCredentialStatus) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.statusCache[documentId] = status
        }
    }
    
    // MARK: - Persistence
    
    func loadPersistedRevokedIds() {
        let ids = getPersistedRevokedIds()
        if !ids.isEmpty {
            // Pre-populate cache with revoked status for persisted IDs
            cacheQueue.async(flags: .barrier) { [weak self] in
                for id in ids {
                    self?.statusCache[id] = .revoked
                }
            }
        }
    }
    
    func addToPersistedRevoked(ids: [String]) {
        var current = getPersistedRevokedIds()
        current.append(contentsOf: ids.filter { !current.contains($0) })
        UserDefaults.standard.set(current, forKey: revokedStorageKey)
    }
    
    func removeFromPersistedRevoked(ids: [String]) {
        var current = getPersistedRevokedIds()
        current.removeAll { ids.contains($0) }
        UserDefaults.standard.set(current, forKey: revokedStorageKey)
    }
    
    // MARK: - Notifications
    
    func notifyDocumentsRevoked(documents: [String: String]) {
        scheduleRevocationNotifications(for: documents)
    }

    /// Posts one local notification per newly revoked document, naming it in the
    /// body. The per-document identifier (`revocation.<id>`) keeps re-checks from
    /// stacking duplicate banners for the same document.
    func scheduleRevocationNotifications(for documents: [String: String]) {
        let title = WalletStringKey.documentRevokedPushTitle.localized()
        for (displayName, documentId) in documents {
            notificationScheduler.schedule(
                title: title,
                body: WalletStringKey.documentRevokedPushBody.localized(with: displayName),
                identifier: "revocation.\(documentId)"
            )
        }
    }
    
    func notifyListRefresh() {
        emitStatusUpdate()
    }
    
    func emitStatusUpdate() {
        let continuations = continuationsQueue.sync { statusContinuations.values.map { $0 } }
        DispatchQueue.main.async {
            continuations.forEach { $0.yield(()) }
        }
    }
}
