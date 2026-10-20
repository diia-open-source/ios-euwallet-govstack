//
//  QRCodeView.swift
//

import UIKit
import Lottie
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public class QRCodeView: BaseCodeView {

    // MARK: - Subviews
    private let titleLabel: UILabel = {
        let label = UILabel().withParameters(
            font: FontBook.usualFont,
            textAlignment: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let qrCodeView: DSQRCodeMlcView = {
        let view = DSQRCodeMlcView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var imagePlaceholder: LottieAnimationView = {
        let animation = LottieAnimation.named(Constants.animationName)
        let lottieView = LottieAnimationView(animation: animation)
        lottieView.loopMode = .loop
        lottieView.backgroundBehavior = .pauseAndRestore
        return lottieView
    }()

    private let errorView: StubMessageViewV2 = {
        let view = StubMessageViewV2()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - Init
    public override func setupSubviews() {
        backgroundColor = .white
        layer.masksToBounds = true
        layer.cornerRadius = Constants.cornerRadius
        isAccessibilityElement = false

        addSubviews([titleLabel, qrCodeView, errorView])
        qrCodeView.addSubview(imagePlaceholder)

        imagePlaceholder.withSize(Constants.placeholderSize)
        NSLayoutConstraint.activate([
            imagePlaceholder.centerXAnchor.constraint(equalTo: qrCodeView.centerXAnchor),
            imagePlaceholder.centerYAnchor.constraint(equalTo: qrCodeView.centerYAnchor),

            titleLabel.bottomAnchor.constraint(equalTo: qrCodeView.topAnchor, constant: -32),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            qrCodeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            qrCodeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            qrCodeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor),

            errorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.errorHorizontalInset),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.errorHorizontalInset),
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Public Methods
    public func configure(title: String, link: String) {
        errorView.isHidden = true
        qrCodeView.isHidden = false
        titleLabel.isHidden = false
        titleLabel.text = title
        qrCodeView.configure(for: .init(qrLink: link))
        setupQRCodeAccessibility(title: title)
    }

    public func setLoadingState(_ state: LoadingState) {
        switch state {
        case .loading:
            imagePlaceholder.isHidden = false
            imagePlaceholder.play()
        case .ready:
            imagePlaceholder.isHidden = true
            imagePlaceholder.stop()
        }
    }

    public func showError(title: String, message: String, buttonTitle: String? = nil, buttonAction: Callback? = nil) {
        setLoadingState(.ready)
        qrCodeView.isHidden = true
        titleLabel.isHidden = true
        errorView.configure(with: StubMessageViewModel(
            title: title,
            btnTitle: buttonTitle,
            descriptionText: message,
            componentId: Constants.errorComponentId,
            repeatAction: buttonAction
        ))
        errorView.isHidden = false
        accessibilityElements = nil
    }

    private func setupQRCodeAccessibility(title: String) {
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .staticText
        titleLabel.accessibilityLabel = title

        qrCodeView.isAccessibilityElement = true
        qrCodeView.accessibilityTraits = .image
        qrCodeView.accessibilityLabel = title

        imagePlaceholder.isAccessibilityElement = false
        accessibilityElements = [titleLabel, qrCodeView]
    }
}

// MARK: - Constants
private extension QRCodeView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let placeholderSize = CGSize(width: 60, height: 60)
        static let animationName = "placeholder_black"
        static let errorHorizontalInset: CGFloat = 24
        static let errorComponentId = "eudi_qr_bluetooth_error"
    }
}
