import UIKit
import AVFoundation
import DiiaUIComponents

final class QRCodeScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}

final class QRCodeScannerOverlayView: BaseCodeView {
    let previewView = QRCodeScannerPreviewView()
    var onBackTap: (() -> Void)?

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let alertLabel = UILabel()
    private let topDimView = UIView()
    private let bottomDimView = UIView()
    private let leftDimView = UIView()
    private let rightDimView = UIView()
    private let scanWindowView = UIView()
    private let leftTopCornerImageView: UIImageView
    private let leftBottomCornerImageView: UIImageView
    private let rightTopCornerImageView: UIImageView
    private let rightBottomCornerImageView: UIImageView
    private let backButtonImage: UIImage?
    private var currentErrorMessage: String?

    init(images: QRCodeScannerImages) {
        self.backButtonImage = images.backButton
        self.leftTopCornerImageView = UIImageView(image: images.leftTopCorner)
        self.leftBottomCornerImageView = UIImageView(image: images.leftBottomCorner)
        self.rightTopCornerImageView = UIImageView(image: images.rightTopCorner)
        self.rightBottomCornerImageView = UIImageView(image: images.rightBottomCorner)
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func setupSubviews() {
        backgroundColor = .clear

        [
            previewView,
            topDimView,
            bottomDimView,
            leftDimView,
            rightDimView,
            scanWindowView,
            backButton,
            titleLabel,
            descriptionLabel,
            alertLabel,
            leftTopCornerImageView,
            leftBottomCornerImageView,
            rightTopCornerImageView,
            rightBottomCornerImageView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        setupStyle()
        setupLayout()
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    func configure(viewState: QRCodeScannerViewState) {
        titleLabel.text = viewState.title
        descriptionLabel.text = viewState.description
        backButton.accessibilityLabel = viewState.backAccessibilityLabel

        titleLabel.accessibilityLabel = viewState.title
        descriptionLabel.accessibilityLabel = viewState.description
    }

    func setErrorMessage(_ message: String?) {
        alertLabel.text = message
        alertLabel.accessibilityLabel = message
        alertLabel.isAccessibilityElement = message?.isEmpty == false
        if let message, !message.isEmpty, message != currentErrorMessage {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        currentErrorMessage = message
    }

    @objc private func backButtonTapped() {
        onBackTap?()
    }

    private func setupStyle() {
        previewView.backgroundColor = .black
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill

        [topDimView, bottomDimView, leftDimView, rightDimView].forEach {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        }

        [leftTopCornerImageView, leftBottomCornerImageView, rightTopCornerImageView, rightBottomCornerImageView].forEach {
            $0.contentMode = .scaleAspectFit
        }

        backButton.tintColor = .white
        backButton.setImage(backButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        backButton.contentHorizontalAlignment = .left
        backButton.isAccessibilityElement = true
        backButton.accessibilityTraits = .button

        titleLabel.font = FontBook.mainFont.regular.size(17)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.isAccessibilityElement = true

        descriptionLabel.font = FontBook.mainFont.regular.size(12)
        descriptionLabel.textColor = .white
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.isAccessibilityElement = true

        alertLabel.font = FontBook.mainFont.regular.size(12)
        alertLabel.textColor = .white
        alertLabel.textAlignment = .center
        alertLabel.numberOfLines = 0
        alertLabel.isAccessibilityElement = false
        alertLabel.accessibilityTraits = .staticText
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),

            scanWindowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scanWindowView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scanWindowView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            scanWindowView.widthAnchor.constraint(equalTo: scanWindowView.heightAnchor),

            topDimView.topAnchor.constraint(equalTo: topAnchor),
            topDimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDimView.bottomAnchor.constraint(equalTo: scanWindowView.topAnchor),

            bottomDimView.topAnchor.constraint(equalTo: scanWindowView.bottomAnchor),
            bottomDimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftDimView.topAnchor.constraint(equalTo: scanWindowView.topAnchor),
            leftDimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftDimView.trailingAnchor.constraint(equalTo: scanWindowView.leadingAnchor),
            leftDimView.bottomAnchor.constraint(equalTo: scanWindowView.bottomAnchor),

            rightDimView.topAnchor.constraint(equalTo: scanWindowView.topAnchor),
            rightDimView.leadingAnchor.constraint(equalTo: scanWindowView.trailingAnchor),
            rightDimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightDimView.bottomAnchor.constraint(equalTo: scanWindowView.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 34),
            descriptionLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -34),
            descriptionLabel.bottomAnchor.constraint(equalTo: scanWindowView.topAnchor, constant: -32),

            alertLabel.topAnchor.constraint(equalTo: scanWindowView.bottomAnchor, constant: 20),
            alertLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 34),
            alertLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -34),

            leftTopCornerImageView.leadingAnchor.constraint(equalTo: scanWindowView.leadingAnchor, constant: -2),
            leftTopCornerImageView.topAnchor.constraint(equalTo: scanWindowView.topAnchor, constant: -2),
            leftTopCornerImageView.widthAnchor.constraint(equalToConstant: 18),
            leftTopCornerImageView.heightAnchor.constraint(equalToConstant: 18),

            leftBottomCornerImageView.leadingAnchor.constraint(equalTo: scanWindowView.leadingAnchor, constant: -2),
            leftBottomCornerImageView.bottomAnchor.constraint(equalTo: scanWindowView.bottomAnchor, constant: 2),
            leftBottomCornerImageView.widthAnchor.constraint(equalToConstant: 18),
            leftBottomCornerImageView.heightAnchor.constraint(equalToConstant: 18),

            rightTopCornerImageView.trailingAnchor.constraint(equalTo: scanWindowView.trailingAnchor, constant: 2),
            rightTopCornerImageView.topAnchor.constraint(equalTo: scanWindowView.topAnchor, constant: -2),
            rightTopCornerImageView.widthAnchor.constraint(equalToConstant: 18),
            rightTopCornerImageView.heightAnchor.constraint(equalToConstant: 18),

            rightBottomCornerImageView.trailingAnchor.constraint(equalTo: scanWindowView.trailingAnchor, constant: 2),
            rightBottomCornerImageView.bottomAnchor.constraint(equalTo: scanWindowView.bottomAnchor, constant: 2),
            rightBottomCornerImageView.widthAnchor.constraint(equalToConstant: 18),
            rightBottomCornerImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}
