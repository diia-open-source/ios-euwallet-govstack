//
//  DocumentsQRViewController.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

protocol DocumentsQRView: BaseView {
    func configureQR(with link: String)
    func showQRError(title: String, message: String, buttonTitle: String?, buttonAction: Callback?)
    func dismissQR()
}

final class DocumentsQRViewController: UIViewController, ChildSubcontroller {

    private let closeButtonImage: UIImage?

    init(closeButtonImage: UIImage?) {
        self.closeButtonImage = closeButtonImage
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Subviews
    private lazy var blurView: CustomIntensityVisualEffectView = {
        let view = CustomIntensityVisualEffectView(
            effect: UIBlurEffect(style: .dark),
            intensity: Constants.blurIntensity
        )
        view.backgroundColor = Constants.blurBackgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    public lazy var qrCodeView: QRCodeView = {
        let qrCodeView = QRCodeView()
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        return qrCodeView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.setBackgroundColor(.white, for: .normal)
        button.setImage(closeButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .black
        button.layer.cornerRadius = Constants.closeButtonCornerRadius
        button.layer.masksToBounds = true
        button.imageEdgeInsets = Constants.closeButtonInsets
        button.accessibilityLabel = WalletStringKey.generalAccessibilityClose.localized()
        button.accessibilityTraits = .button
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var cardTopPadding: CGFloat = {
        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
        let cardContainerBottomPadding: CGFloat = safeAreaInsets.bottom + Constants.tabbarHeight + Constants.cardContainerBottomPadding
        let cardContainerHeight = view.frame.height - safeAreaInsets.top - cardContainerBottomPadding // Documents collection height
        return (cardContainerHeight - DocumentsLayoutProvider.cardHeight) / 2
    }()
    
    // MARK: - Properties
    var container: ContainerProtocol?
    var presenter: DocumentsQRAction!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        presenter.configureView()
    }

    private func setupSubviews() {
        qrCodeView.setLoadingState(.ready)

        view.addSubviews([blurView, qrCodeView, closeButton])
        
        blurView.fillSuperview()
        closeButton.withSize(Constants.closeButtonSize)
        
        NSLayoutConstraint.activate([
            qrCodeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: cardTopPadding),
            qrCodeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            qrCodeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            qrCodeView.heightAnchor.constraint(equalToConstant: DocumentsLayoutProvider.cardHeight),
            
            closeButton.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 32),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        presenter.handleCloseAction()
    }
}

// MARK: - View Logic
extension DocumentsQRViewController: DocumentsQRView {
    func configureQR(with link: String) {
        qrCodeView.setLoadingState(.ready)
        qrCodeView.configure(title: WalletStringKey.documentsQrHoldToReader.localized(), link: link)
    }

    func showQRError(title: String, message: String, buttonTitle: String?, buttonAction: Callback?) {
        qrCodeView.showError(title: title, message: message, buttonTitle: buttonTitle, buttonAction: buttonAction)
    }

    func dismissQR() {
        container?.close()
    }
}

// MARK: - Constants
extension DocumentsQRViewController {
    private enum Constants {
        static let blurIntensity: CGFloat = 0.15
        static let blurBackgroundColor: UIColor = .black.withAlphaComponent(0.2)
        
        static let closeButtonSize: CGSize = .init(width: 44, height: 44)
        static let closeButtonInsets: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
        static let closeButtonCornerRadius: CGFloat = 22
        
        static let tabbarHeight: CGFloat = 70
        static let cardContainerBottomPadding: CGFloat = 16
    }
}
