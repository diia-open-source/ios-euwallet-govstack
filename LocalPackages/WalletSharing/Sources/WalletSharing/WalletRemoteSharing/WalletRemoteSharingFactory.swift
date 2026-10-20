import DiiaMVPModule
import WalletCore
import WalletDomainModels

/// Package-side implementation of `WalletRemoteSharingPresenting`.
///
/// Constructs `WalletRemoteSharingModule` directly. The app bootstraps this as
/// `WalletDependencies.remoteSharingPresenter` so other wallet feature packages
/// (e.g. `WalletIssuing` during authorization-code redirects) can launch the
/// remote-sharing flow without importing `WalletSharing`.
public struct WalletRemoteSharingFactory: WalletRemoteSharingPresenting {
    public init() {}

    public func makeRemoteSharingModule(
        link: String,
        redirectCallback: @escaping (String) -> Void
    ) -> BaseModule {
        WalletRemoteSharingModule(link: link, redirectCallback: redirectCallback)
    }
}
