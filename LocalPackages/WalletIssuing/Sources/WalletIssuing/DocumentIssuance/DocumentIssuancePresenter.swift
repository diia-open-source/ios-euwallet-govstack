//
//  DocumentIssuancePresenter.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices
import WalletCore
import WalletDomainModels

final class DocumentIssuancePresenter: ConstructorScreenPresenter {

    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    private let walletKit: WalletKitProtocol
    private let viewStateFactory: DocumentIssuanceViewStateFactoryProtocol

    private let offerUri: String
    private var offer: IssuanceOffer?
    private var txCodeValue: String?

    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        offerUri: String,
        viewStateFactory: DocumentIssuanceViewStateFactoryProtocol
    ) {
        self.view = view
        self.offerUri = offerUri
        self.viewStateFactory = viewStateFactory
        self.walletKit = WalletDependencies.walletController
    }
    
    // MARK: - Public Methods
    func configureView() {
        view.showProgress()
        Task { [weak self] in
            guard let self else { return }
            do {
                let offer = try await self.walletKit.resolveOfferUrlDocTypes(offerUri: offerUri)
                if self.hasUnsupportedDocument(in: offer) {
                    await MainActor.run {
                        self.view.hideProgress()
                        self.handleAlert(alert: Constants.unsupportedDocumentAlert)
                    }
                    return
                }
                if self.isMdlOfferWithoutPid(offer) {
                    await MainActor.run {
                        self.view.hideProgress()
                        self.handleAlert(alert: Constants.pidNotFoundAlert)
                    }
                    return
                }
                if self.hasDuplicateDocument(for: offer) {
                    await MainActor.run {
                        self.view.hideProgress()
                        self.handleAlert(alert: Constants.duplicateDocumentAlert)
                    }
                    return
                }

                self.offer = offer
                await MainActor.run {
                    self.buildScreen()
                }
            } catch {
                await MainActor.run {
                    self.view.hideProgress()
                    self.handleAlert(alert: self.alert(for: error))
                }
            }
        }
    }
    
    func handleEvent(event: ConstructorItemEvent) {
        switch event {
        case .inputChanged:
            view.inputFieldsWasUpdated()
        default:
            guard let action = event.actionParameters(),
                  let screenAction = DocumentIssuanceScreenAction(rawValue: action.type)
            else { return }
            handleScreenAction(screenAction)
        }
    }
    
    // MARK: - Private Methods -

    // TODO: App-side workaround — remove once the SDK is fixed.
    // The real bug is in EudiWalletKit's `SimpleAuthenticationPresentationContext` (OpenId4VciService.swift): it hands `ASWebAuthenticationSession` a detached `ASPresentationAnchor()` instead of the app's real foreground key window, so the session only presents reliably when the app is already foreground-active.
    // The proper fix is to return the active scene's key window from `presentationAnchor`.
    // When that lands upstream (or in our fork bump), delete this gate and its call site.

    /// Suspends until the app's window scene is `.foregroundActive`, so issuance can safely present its `ASWebAuthenticationSession`.
    ///
    /// After the PIN/biometry gate the scene briefly leaves `.foregroundActive`, and presenting the web-auth session before it returns fails with "Web authentication presentation context invalid."
    /// We await the next scene-activation event rather than poll, bounded by `timeout` so issuance can never hang.
    /// The document-list flow has no gate and is already active, so this returns immediately.
    @MainActor
    private func waitForForegroundActive(timeout: TimeInterval = 3) async {
        guard !isSceneForegroundActive else { return }

        var observer: NSObjectProtocol?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var resumed = false
            // Resume exactly once — whichever fires first, scene activation or timeout.
            func finish(timedOut: Bool) {
                guard !resumed else { return }
                resumed = true
                observer.map(NotificationCenter.default.removeObserver)
                continuation.resume()
            }
            observer = NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification, object: nil, queue: .main
            ) { [weak self] _ in
                if self?.isSceneForegroundActive == true { finish(timedOut: false) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { finish(timedOut: true) }
        }
    }

    private var isSceneForegroundActive: Bool {
        UIApplication.shared.connectedScenes.contains { $0.activationState == .foregroundActive }
    }

    private func issueDocument() {
        guard let offer else { return }
        guard !isMdlOfferWithoutPid(offer) else {
            handleAlert(alert: Constants.pidNotFoundAlert)
            return
        }
        guard !hasDuplicateDocument(for: offer) else {
            handleAlert(alert: Constants.duplicateDocumentAlert)
            return
        }
        guard !offer.isTxCodeRequired || txCodeValue != nil else {
            presentTxCodeInput()
            return
        }

        view.showProgress()
        Task { [weak self] in
            guard let self else { return }
            do {
                // The credential-offer / QR flow runs a PIN/biometry gate before this, which momentarily drops the scene out of `.foregroundActive`.
                // The SDK issuance presents an `ASWebAuthenticationSession` over a detached presentation anchor that only adopts a foreground-active scene, so presenting before the scene settles fails with "Web authentication presentation context invalid."
                // Wait for the window state to recover (the document-list flow has no gate and returns from this immediately).
                await self.waitForForegroundActive()
                let documents = try await self.walletKit.issueDocuments(
                    forOffer: offer,
                    txCodeValue: txCodeValue
                )
                await MainActor.run {
                    if documents.contains(where: { $0.isDeferred }) {
                        self.processDeferredIssuance()
                    } else if let presentationUrl = documents.first?.authorizePresentationUrl {
                        self.openPresentationModule(with: presentationUrl)
                    } else {
                        self.processSuccessIssuance()
                    }
                }
            } catch {
                await MainActor.run {
                    self.txCodeValue = nil
                    self.view.hideProgress()
                    if self.isInvalidTxCodeError(error) {
                        self.handleIncorrectTxCodeAlert()
                    } else {
                        self.handleAlert(alert: self.alert(for: error))
                    }
                }
            }
        }
    }

    private func hasDuplicateDocument(for offer: IssuanceOffer) -> Bool {
        guard let offerIssuerId = issuerId(from: offerUri) else {
            return false
        }

        let normalizedOfferIssuerId = normalizedIssuerId(offerIssuerId)
        let offeredDocumentTypes = Set(offer.documents.compactMap(\.docTypeOrVct))
        guard !offeredDocumentTypes.isEmpty else { return false }

        return walletKit.fetchAllDocumentsIncludingDeferred().contains { document in
            guard let storedIssuerId = document.credentialIssuerIdentifier else { return false }
            return offeredDocumentTypes.contains(document.docType)
                && normalizedIssuerId(storedIssuerId) == normalizedOfferIssuerId
        }
    }

    /// True if the offer contains any document the app can't issue.
    /// Supported types are exactly the `WalletDocumentType` cases; an offer with a single unrecognized
    /// `docTypeOrVct` (or a missing one) is blocked entirely — we never show the add screen for a partially-supported offer.
    private func hasUnsupportedDocument(in offer: IssuanceOffer) -> Bool {
        offer.documents.contains { offeredDocument in
            guard let docTypeOrVct = offeredDocument.docTypeOrVct else { return true }
            return WalletDocumentType(rawValue: docTypeOrVct) == nil
        }
    }

    private func isMdlOfferWithoutPid(_ offer: IssuanceOffer) -> Bool {
        let containsMdl = offer.documents.contains { offeredDocument in
            offeredDocument.docTypeOrVct == WalletDocumentType.mdl.rawValue
                || offeredDocument.displayName.localizedCaseInsensitiveContains(WalletDocumentType.mdl.displayName)
        }

        guard containsMdl else { return false }

        let hasPid = walletKit.fetchAllDocuments().contains { document in
            WalletDocumentType.allPidTypes.map(\.rawValue).contains(document.docType)
        }

        return !hasPid
    }
    
    /// Handles OpenID4VCI dynamic issuance — a.k.a. presentation during issuance (spec Appendix H.5).
    /// The issuer's authorization step returned an `authorizePresentationUrl`, so the wallet must complete an OpenID4VP presentation (e.g. present an existing PID) before the credential is issued.
    /// This runs that presentation via the shared remote-sharing module and, on the verifier redirect, calls `resumePendingIssuance` to finish.
    private func openPresentationModule(with url: String) {
        // `view.replace` below removes the issuance screen — deallocating this presenter and its unowned `view` — and the live remote module closes immediately after invoking this, so the callback must capture neither.
        // Drive the resume through WalletDependencies instead; the refreshed document list is the visible result, and a deferred result starts the coordinator whose own alert fires on completion.
        let redirectCallback: (String) -> Void = { redirectUrl in
            Task {
                do {
                    let doc = try await WalletDependencies.walletController.resumePendingIssuance(webUrl: redirectUrl)
                    try? await WalletDependencies.walletController.loadDocuments()
                    await MainActor.run {
                        WalletDependencies.documentsRefresher.walletDidRefreshDocuments()
                        if doc.isDeferred {
                            WalletDependencies.walletLifecycle.deferredCoordinator.kick()
                        }
                    }
                } catch {
                    // No live view remains to surface an error; the credential is simply not added.
                }
            }
        }
        let module = WalletDependencies.remoteSharingPresenter.makeRemoteSharingModule(
            link: url,
            redirectCallback: redirectCallback
        )
        view.replace(with: module, animated: true)
    }
    
    private func processDeferredIssuance() {
        Task {
            do {
                try await WalletDependencies.walletController.loadDocuments()
            } catch { }
            await MainActor.run {
                WalletDependencies.documentsRefresher.walletDidRefreshDocuments()
                WalletDependencies.walletLifecycle.deferredCoordinator.kick()
                view.hideProgress()
                handleAlert(alert: Constants.deferredPendingAlert)
            }
        }
    }

    private func processSuccessIssuance() {
        Task {
            do {
                try await WalletDependencies.walletController.loadDocuments()
            } catch { }
            await MainActor.run {
                WalletDependencies.documentsRefresher.walletDidRefreshDocuments()
                view.hideProgress()
                handleAlert(alert: Constants.successAlert)
            }
        }
    }
    
    private func buildScreen() {
        guard let offer else { return }
        view.hideProgress()
        view.configure(model: viewStateFactory.make(offer: offer))
    }
    
    private func presentTxCodeInput() {
        view.hideProgress()
        let module = DocumentTxCodeInputModule(
            txCodeSpec: offer?.txCodeSpec,
            onSubmit: { [weak self] txCode in
                guard let self else { return }
                self.txCodeValue = txCode
                self.issueDocument()
            },
            onClose: { [weak self] in
                self?.txCodeValue = nil
            }
        )
        view.present(module: module)
    }
    
    // MARK: - Handlers
    private func handleScreenAction(_ action: DocumentIssuanceScreenAction) {
        switch action {
        case .issueDocument:
            // A pre-authorized offer that carries a transaction code authenticates the user through that code, so the wallet PIN/biometry gate is redundant — skip it and issue directly (issuance then presents the tx-code input).
            // Every other offer (authorization-code flow, or pre-authorized without a code) keeps the PIN gate as the only local authentication before we contact the issuer.
            if offer?.isTxCodeRequired == true {
                issueDocument()
            } else {
                showAuthBeforeIssue { [weak self] in
                    self?.issueDocument()
                }
            }
        case .dismiss, .back:
            view.closeModule(animated: true)
        }
    }

    /// PIN/biometry gate before contacting the issuer.
    /// Mirrors the remote/proximity sharing flows, which authenticate via
    /// `WalletDependencies.authGate` immediately before sending credentials.
    /// Both entry points into issuance (deep link and QR scan) open
    /// `DocumentIssuanceModule`, so gating here covers both.
    private func showAuthBeforeIssue(onSuccess: @escaping () -> Void) {
        WalletDependencies.authGate.presentAuthBeforeSend(
            in: view,
            onSuccess: onSuccess,
            onCancel: { }
        )
    }

    private func handleAlert(alert: AlertTemplate) {
        WalletDependencies.templatePresenter.handle(alert, in: view) { [weak self] _ in
            guard let self = self else { return }
            self.view.closeModule(animated: true)
        }
    }

    private func handleIncorrectTxCodeAlert() {
        WalletDependencies.templatePresenter.handle(Constants.incorrectTxCodeAlert, in: view) { [weak self] _ in
            self?.view.closeModule(animated: true)
        }
    }

    private func issuerId(from offerUri: String) -> String? {
        guard let components = URLComponents(string: offerUri) else { return nil }
        let queryItems = components.queryItems ?? []

        if let credentialOffer = queryItems.first(where: { $0.name == Constants.credentialOfferQueryItem })?.value,
           let issuerId = issuerIdFromInlineCredentialOffer(credentialOffer) {
            return issuerId
        }

        if let credentialOfferUri = queryItems.first(where: { $0.name == Constants.credentialOfferUriQueryItem })?.value,
           let issuerUrl = URL(string: credentialOfferUri),
           let host = issuerUrl.host {
            return host
        }

        return nil
    }

    private func issuerIdFromInlineCredentialOffer(_ credentialOffer: String) -> String? {
        guard let data = credentialOffer.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let issuerId = json[Constants.credentialIssuerJsonKey] as? String
        else { return nil }

        return issuerId
    }

    private func normalizedIssuerId(_ issuerId: String) -> String {
        if let url = URL(string: issuerId), let host = url.host {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return (path.isEmpty ? host : "\(host)/\(path)").lowercased()
        }

        return issuerId
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }

    /// Picks the dedicated "Untrusted issuer" alert when the issuer's signed metadata failed certificate validation; otherwise the generic issuance error.
    private func alert(for error: Error) -> AlertTemplate {
        if let domainError = error as? WalletDomainError, case .issuerNotTrusted = domainError {
            return Constants.untrustedIssuerAlert
        }
        return Constants.makeErrorAlert()
    }

    private func isInvalidTxCodeError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == Constants.credentialIssuanceErrorDomain,
           nsError.code == Constants.invalidTxCodeErrorCode {
            return true
        }

        let message = error.localizedDescription.lowercased()
        return message.contains("tx code")
            || message.contains("transaction code")
            || message.contains("invalid_grant")
    }
}

// MARK: - DocumentIssuancePresenter+Constants
private extension DocumentIssuancePresenter {
    enum Constants {
        static let credentialOfferQueryItem = "credential_offer"
        static let credentialOfferUriQueryItem = "credential_offer_uri"
        static let credentialIssuerJsonKey = "credential_issuer"
        static let duplicateDocumentIcon: DSIconKey = .attentionBlackRound
        static let successIcon: DSIconKey = .doneBlackRound
        static let credentialIssuanceErrorDomain = "OpenID4VCI.CredentialIssuanceError"
        static let invalidTxCodeErrorCode = 5
        
        static func makeErrorAlert(details: String? = nil) -> AlertTemplate {
            .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: duplicateDocumentIcon,
                    title: WalletStringKey.issuanceErrorTitle.localized(),
                    description: details ?? WalletStringKey.issuanceErrorDescription.localized(),
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.generalProblemOk.localized(),
                        icon: nil,
                        action: .cancel),
                    alternativeButton: nil)
            )
        }

        static var deferredPendingAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: successIcon,
                title: WalletStringKey.deferredIssuancePendingTitle.localized(),
                description: WalletStringKey.deferredIssuancePendingDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok),
                alternativeButton: nil)
        )

        static var successAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: successIcon,
                title: WalletStringKey.issuanceSuccessTitle.localized(),
                description: WalletStringKey.issuanceSuccessDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.issuanceSuccessButton.localized(),
                    icon: nil,
                    action: .ok),
                    alternativeButton: nil)
        )

        static var duplicateDocumentAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: duplicateDocumentIcon,
                title: WalletStringKey.issuanceDuplicateDocumentTitle.localized(),
                description: WalletStringKey.issuanceDuplicateDocumentDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalCancel.localized(),
                    icon: nil,
                    action: .cancel),
                alternativeButton: nil)
        )

        static var untrustedIssuerAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: duplicateDocumentIcon,
                title: WalletStringKey.issuanceUntrustedIssuerTitle.localized(),
                description: WalletStringKey.issuanceUntrustedIssuerDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.issuanceUntrustedIssuerButton.localized(),
                    icon: nil,
                    action: .cancel),
                alternativeButton: nil)
        )

        static var pidNotFoundAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: duplicateDocumentIcon,
                title: WalletStringKey.issuancePidNotFoundTitle.localized(),
                description: WalletStringKey.issuancePidNotFoundDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel),
                alternativeButton: nil)
        )

        static var unsupportedDocumentAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: duplicateDocumentIcon,
                title: WalletStringKey.issuanceUnsupportedDocumentTitle.localized(),
                description: WalletStringKey.issuanceUnsupportedDocumentDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel),
                alternativeButton: nil)
        )

        static var incorrectTxCodeAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: duplicateDocumentIcon,
                title: WalletStringKey.issuanceErrorTitle.localized(),
                description: WalletStringKey.issuanceErrorDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel),
                alternativeButton: nil)
        )
    }
}
