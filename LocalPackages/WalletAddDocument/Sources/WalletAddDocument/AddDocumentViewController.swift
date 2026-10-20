import UIKit
import DiiaUIComponents
import WalletCore
import WalletDomainModels

protocol AddDocumentView: ConstructorScreenViewProtocol {
    func setQRButtonHidden(_ isHidden: Bool)
}

final class AddDocumentViewController: ConstructorViewController {
    private let qrButton = UIButton(type: .custom)
    var qrButtonImage: UIImage? {
        didSet { qrButton.setImage(qrButtonImage, for: .normal) }
    }

    override func didLoadConstructorView() {
        addFloatingButton()
    }

    func addFloatingButton() {
        qrButton.setImage(qrButtonImage, for: .normal)
        qrButton.accessibilityLabel = WalletStringKey.addDocumentScanQr.localized()
        qrButton.addTarget(self, action: #selector(qrButtonTapped), for: .touchUpInside)
        qrButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(qrButton)
        NSLayoutConstraint.activate([
            qrButton.widthAnchor.constraint(equalToConstant: Constants.qrButtonSize),
            qrButton.heightAnchor.constraint(equalToConstant: Constants.qrButtonSize),
            qrButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalPadding),
            qrButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.qrButtonBottomPadding)
        ])
    }

    @objc private func qrButtonTapped() {
        presenter.handleEvent(event: .action(DSActionParameter(action: AddDocumentScreenAction.openScanQR)))
    }
}

extension AddDocumentViewController: AddDocumentView {
    func setQRButtonHidden(_ isHidden: Bool) {
        qrButton.isHidden = isHidden
    }
}

private extension AddDocumentViewController {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let qrButtonSize: CGFloat = 56
        static let qrButtonBottomPadding: CGFloat = 16
    }
}
