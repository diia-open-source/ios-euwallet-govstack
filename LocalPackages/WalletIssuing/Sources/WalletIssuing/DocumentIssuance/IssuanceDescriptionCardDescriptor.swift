import Foundation
import DiiaUIComponents
import WalletCore
import WalletDomainModels

extension DSComponent where Model == IssuanceDescriptionCardModel {
    static var eudiIssuanceDescriptionCard: Self { .init(key: IssuanceDescriptionCardBuilder.key) }
}
