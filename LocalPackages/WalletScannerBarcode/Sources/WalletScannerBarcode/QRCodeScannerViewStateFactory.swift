import Foundation
import DiiaUIComponents
import WalletCore
import WalletDomainModels

struct QRCodeScannerViewState {
    let constructorModel: DSConstructorModel
    let title: String
    let description: String
    let closeAlertTitle: String
    let closeAlertMessage: String
    let closeAlertActionTitle: String
    let backAccessibilityLabel: String
}

protocol QRCodeScannerViewStateFactoryProtocol {
    func make() -> QRCodeScannerViewState
}

struct QRCodeScannerViewStateFactory: QRCodeScannerViewStateFactoryProtocol {
    func make() -> QRCodeScannerViewState {
        QRCodeScannerViewState(
            constructorModel: DSConstructorModel(),
            title: WalletStringKey.qrScannerTitle.localized(),
            description: WalletStringKey.qrScannerDescription.localized(),
            closeAlertTitle: WalletStringKey.photoProblem.localized(),
            closeAlertMessage: WalletStringKey.photoProblemDescription.localized(),
            closeAlertActionTitle: WalletStringKey.generalProblemOk.localized(),
            backAccessibilityLabel: WalletStringKey.generalAccessibilityBackButtonLabel.localized()
        )
    }
}
