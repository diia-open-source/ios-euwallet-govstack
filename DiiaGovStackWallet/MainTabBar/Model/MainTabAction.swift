import Foundation
import WalletCore
import WalletDomainModels

enum MainTabAction: Equatable {
    case settings
    case publicService
    case documents(type: DocType?)

    static func == (lhs: MainTabAction, rhs: MainTabAction) -> Bool {
        switch (lhs, rhs) {
        case (.settings, .settings),
            (.publicService, .publicService):
            return true
        case (let .documents(lValue), let .documents(rValue)):
            return lValue == rValue
        default:
            return false
        }
    }
}
