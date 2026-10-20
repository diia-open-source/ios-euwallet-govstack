import Foundation
import WalletDocumentsCommonTypes
import WalletGallery
import WalletCore
import WalletDomainModels

/// Bridges `WalletCore`'s document-refresh hook to app-side `DocumentsProcessor` and
/// the `documentsWasReordered` notification.
struct AppWalletDocumentsRefresher: WalletDocumentsRefreshing {
    @MainActor
    func walletDidRefreshDocuments() {
        DocumentsProcessor.instance.refreshAllFromStorage()
        NotificationCenter.default.post(
            name: DocumentsConstants.Notifications.documentsWasReordered,
            object: nil
        )
    }
}
