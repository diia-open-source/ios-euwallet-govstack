//
//  DSPidActivateCardView.swift
//
//

import UIKit
import Lottie
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes

public struct PidActivateCardViewModel {
    public let image: UIImage?
    public let imageUrl: String?
    public let title: String
    public let description: String
    public let btnStrokeDefaultAtm: DSButtonModel
    public let eventHandler: (ConstructorItemEvent) -> Void
    
    public init(
        image: UIImage?,
        title: String,
        description: String,
        btnStrokeDefaultAtm: DSButtonModel,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) {
        self.image = image
        self.imageUrl = nil
        self.title = title
        self.description = description
        self.btnStrokeDefaultAtm = btnStrokeDefaultAtm
        self.eventHandler = eventHandler
    }
    
    public init(
        imageUrl: String,
        title: String,
        description: String,
        btnStrokeDefaultAtm: DSButtonModel,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) {
        self.image = nil
        self.imageUrl = imageUrl
        self.title = title
        self.description = description
        self.btnStrokeDefaultAtm = btnStrokeDefaultAtm
        self.eventHandler = eventHandler
    }
}

public class PidActivateCardView: BaseCodeView, FrontViewProtocol {
    
    // MARK: - Subviews
    private let imageView = UIImageView()
    private let titleLabel = UILabel().withParameters(font: FontBook.emptyStateTitleFont, numberOfLines: Constants.titleNumberOfLines, textAlignment: .center)
    private let descriptionLabel = UILabel().withParameters(font: FontBook.usualFont, numberOfLines: Constants.descriptionNumberOfLines, textAlignment: .center)
    private let defaultButton = ActionLoadingStateButton()
    
    private lazy var imagePlaceholder: LottieAnimationView = {
        let animation = LottieAnimation.named(Constants.animationName)
        let lottieView = LottieAnimationView(animation: animation)
        lottieView.loopMode = .loop
        lottieView.backgroundBehavior = .pauseAndRestore
        return lottieView
    }()

    // MARK: - Properties
    private var viewModel: PidActivateCardViewModel?
    public var contextMenuCallback: Callback?
    
    // MARK: - Init
    public override func setupSubviews() {
        setupUI()
        
        let containerView = UIView()
        addSubview(containerView)
        containerView.addSubviews([imageView, titleLabel, descriptionLabel, defaultButton])
        imageView.addSubview(imagePlaceholder)

        containerView.fillSuperview(padding: Constants.containerViewInsets)
        imageView.anchor(top: containerView.topAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor)
        imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: Constants.imageSizeMultiplier).isActive = true
        titleLabel.anchor(top: imageView.bottomAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, padding: Constants.titleInsets)
        descriptionLabel.anchor(top: titleLabel.bottomAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, padding: Constants.descriptionInsets)
        descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: defaultButton.topAnchor, constant: Constants.descriptionBottomInset).isActive = true

        defaultButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        defaultButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: Constants.buttonBottomInset).isActive = true
        
        imagePlaceholder.withSize(Constants.placeholderSize)
        imagePlaceholder.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        imagePlaceholder.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
    }
    
    // MARK: - Public Methods
    public func configure(with viewModel: PidActivateCardViewModel) {
        self.viewModel = viewModel
        
        titleLabel.setTextWithCurrentAttributes(
            text: viewModel.title,
            lineHeightMultiple: Constants.lineHeightMultiple)
        descriptionLabel.setTextWithCurrentAttributes(
            text: viewModel.description,
            lineHeightMultiple: Constants.lineHeightMultiple)
        
        imageView.isHidden = viewModel.image == nil && viewModel.imageUrl == nil
        imagePlaceholder.isHidden = viewModel.image != nil || viewModel.imageUrl == nil
        if let image = viewModel.image {
            imageView.image = image
        } else if let imageUrl = viewModel.imageUrl {
            imagePlaceholder.play()
            imageView.loadImage(imageURL: imageUrl, completion: { [weak self] in
                self?.imagePlaceholder.stop()
                self?.imagePlaceholder.isHidden = true
            })
        }
        
        defaultButton.setLoadingState(.enabled, withTitle: viewModel.btnStrokeDefaultAtm.label)
        defaultButton.onClick = {
            guard let action = viewModel.btnStrokeDefaultAtm.action else { return }
            viewModel.eventHandler(.action(action))
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = Constants.backgroundCornerRadius
        layer.masksToBounds = true
        
        imageView.layer.cornerRadius = Constants.imageCornerRadius
        imageView.layer.masksToBounds = true
        
        defaultButton.setStyle(style: .light)
        defaultButton.titleLabel?.font = FontBook.bigText
        defaultButton.contentEdgeInsets = Constants.defaultButtonInsets
        defaultButton.withHeight(Constants.defaultButtonHeight)
    }
}

// MARK: - Constants
private extension PidActivateCardView {
    enum Constants {
        static let backgroundCornerRadius: CGFloat = 24
        static let imageCornerRadius: CGFloat = 16
        static let defaultButtonHeight: CGFloat = 48
        static let lineHeightMultiple: CGFloat = 1.25
        
        static let titleNumberOfLines = 2
        static let descriptionNumberOfLines = 4
        
        static let containerViewInsets: UIEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)
        static let titleInsets: UIEdgeInsets = .init(top: 16, left: .zero, bottom: .zero, right: .zero)
        static let descriptionInsets: UIEdgeInsets = .init(top: 16, left: .zero, bottom: .zero, right: .zero)
        static let defaultButtonInsets: UIEdgeInsets = .init(top: .zero, left: 60, bottom: .zero, right: 60)
        
        static let descriptionBottomInset: CGFloat = -16
        static let buttonBottomInset: CGFloat = -16
        static let imageSizeMultiplier: CGFloat = 0.33
        static let placeholderSize = CGSize(width: 60, height: 60)
        
        static let animationName = "placeholder_black"
    }
}

