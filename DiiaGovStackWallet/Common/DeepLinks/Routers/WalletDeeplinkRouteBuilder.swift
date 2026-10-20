//
//  WalletDeeplinkRouteBuilder.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletIssuing
import WalletSharing

public struct WalletDeeplinkRouteBuilder: DeepLinkRouteBuilder {

    private let sharingSchemes: Set<String> = [
        "eudi-openid4vp",
        "mdoc-openid4vp",
        "mdl-openid4vp",
        "openid4vp",
        "haip-vp",
        "haip",
    ]

    private let issuanceSchemes: Set<String> = [
        "openid-credential-offer",
        "haip-vci"
    ]

    public func canCreateRoute(with urlString: String) -> Bool {
        guard let scheme = URL(string: urlString)?.scheme else { return false }
        return sharingSchemes.contains(scheme) || issuanceSchemes.contains(scheme)
    }

    public func needAuth() -> Bool {
        // Defer sharing/issuance links behind the PIN gate — they perform credential operations and must not run over the lock screen.
        return true
    }

    public func create(with urlString: String) -> RouterProtocol? {
        guard let scheme = URL(string: urlString)?.scheme else { return nil }

        if sharingSchemes.contains(scheme) {
            return WalletSharingDeeplinkRouter(urlString: urlString)
        }
        if issuanceSchemes.contains(scheme) {
            return WalletIssuanceDeeplinkRouter(urlString: urlString)
        }

        return nil
    }
}

struct WalletSharingDeeplinkRouter: RouterProtocol {
    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }

    func route(in view: BaseView) {
        let urlStringWithoutScheme = stripScheme(from: urlString)
        let module = WalletRemoteSharingModule(link: urlStringWithoutScheme)
        view.open(module: module)
    }

    private func stripScheme(from link: String) -> String {
        guard let range = link.range(of: "://") else { return link }
        return String(link[range.upperBound...])
    }
}

struct WalletIssuanceDeeplinkRouter: RouterProtocol {
    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }

    func route(in view: BaseView) {
        let module = DocumentIssuanceModule(
            offerUri: urlString,
            viewStateFactory: DocumentIssuanceViewStateFactory()
        )
        view.open(module: module)
    }
}
