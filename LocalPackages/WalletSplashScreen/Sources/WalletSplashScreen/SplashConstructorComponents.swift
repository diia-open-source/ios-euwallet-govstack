import UIKit
import DiiaCommonTypes
import DiiaUIComponents

struct SplashTitleModel: Codable {
    let label: String
    let componentId: String?
}

struct SplashTitleBuilder: DSViewBuilderProtocol {
    static let key = "splashTitle"

    func makeView(
        from object: AnyCodable,
        withPadding padding: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: SplashTitleModel = object.parseValue(forKey: Self.key) else { return nil }
        return SplashTitleView(model: model)
    }
}

struct SplashLogosModel: Codable {
    let componentId: String?
}

struct SplashLogosBuilder: DSViewBuilderProtocol {
    static let key = "splashLogos"

    let logosImage: UIImage?

    func makeView(
        from object: AnyCodable,
        withPadding padding: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: SplashLogosModel = object.parseValue(forKey: Self.key) else { return nil }
        return SplashLogosView(model: model, logosImage: logosImage)
    }
}

private final class SplashTitleView: UIView {
    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let verticalOffset: CGFloat = -24
    }

    private let label = UILabel()

    init(model: SplashTitleModel) {
        super.init(frame: .zero)
        setupLabel(model: model)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        let targetSize = CGSize(
            width: UIScreen.main.bounds.width - Constants.horizontalInset * 2,
            height: UIView.layoutFittingCompressedSize.height
        )
        let labelSize = label.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: labelSize.height + abs(Constants.verticalOffset) * 2)
    }

    private func setupLabel(model: SplashTitleModel) {
        label.font = FontBook.mainFont.regular.size(38)
        label.text = model.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = model.componentId
        label.isAccessibilityElement = true
        label.accessibilityTraits = .header
        label.accessibilityLabel = model.label
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func setupLayout() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: Constants.verticalOffset),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalInset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalInset)
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
}

private final class SplashLogosView: UIView {
    private enum Constants {
        static let imageWidth: CGFloat = 250
        static let imageHeight: CGFloat = 48
        static let bottomOffset: CGFloat = 22
    }

    private let imageView: UIImageView

    init(model: SplashLogosModel, logosImage: UIImage?) {
        self.imageView = UIImageView(image: logosImage)
        super.init(frame: .zero)
        setupImageView(model: model)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: Constants.imageHeight + Constants.bottomOffset
        )
    }

    private func setupImageView(model: SplashLogosModel) {
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = model.componentId
        imageView.isAccessibilityElement = true
    }

    private func setupLayout() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.imageHeight + Constants.bottomOffset),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageWidth),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageHeight)
        ])

        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
