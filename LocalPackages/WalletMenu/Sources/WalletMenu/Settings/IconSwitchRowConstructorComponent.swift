import UIKit
import DiiaCommonTypes
import DiiaUIComponents

struct IconSwitchRowModel: Codable {
    let componentId: String?
    let id: String
    let title: String
    let iconName: String
    let isOn: Bool
    let showSeparator: Bool

    init(componentId: String?, id: String, title: String, iconName: String, isOn: Bool, showSeparator: Bool) {
        self.componentId = componentId
        self.id = id
        self.title = title
        self.iconName = iconName
        self.isOn = isOn
        self.showSeparator = showSeparator
    }
}

final class IconSwitchRowView: UIView {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.bigText
        label.textColor = .black
        return label
    }()

    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = .systemGreen
        return toggle
    }()

    private var rowId: String?
    private var eventHandler: ((ConstructorItemEvent) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func configure(model: IconSwitchRowModel, eventHandler: @escaping (ConstructorItemEvent) -> Void) {
        titleLabel.text = model.title
        let symbolConfig = UIImage.SymbolConfiguration(weight: .bold)
        iconImageView.image = UIImage(named: model.iconName)
            ?? UIImage(systemName: model.iconName, withConfiguration: symbolConfig)
        toggleSwitch.isOn = model.isOn
        toggleSwitch.accessibilityLabel = model.title
        accessibilityIdentifier = model.componentId
        rowId = model.id
        self.eventHandler = eventHandler
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(toggleSwitch)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggleSwitch.leadingAnchor, constant: -16),
            toggleSwitch.trailingAnchor.constraint(equalTo: trailingAnchor),
            toggleSwitch.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        toggleSwitch.addTarget(self, action: #selector(toggleValueChanged), for: .valueChanged)
        iconImageView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        toggleSwitch.isAccessibilityElement = true
    }

    @objc private func toggleValueChanged() {
        guard let rowId else { return }
        eventHandler?(
            .customEvent(
                CustomConstructorEvent(
                    code: IconSwitchRowEventCode.toggleChanged.rawValue,
                    payload: [
                        IconSwitchRowEventPayload.id: rowId,
                        IconSwitchRowEventPayload.isOn: toggleSwitch.isOn
                    ]
                )
            )
        )
    }
}

struct IconSwitchRowBuilder: DSViewBuilderProtocol {
    static let key = "iconSwitchRow"

    func makeView(
        from object: AnyCodable,
        withPadding padding: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: IconSwitchRowModel = object.parseValue(forKey: Self.key) else { return nil }
        let view = IconSwitchRowView()
        view.configure(model: model, eventHandler: eventHandler)
        let insets = padding.defaultPadding(object: object, modelKey: Self.key)

        let container = UIStackView()
        container.axis = .vertical
        container.addArrangedSubview(view)
        if model.showSeparator {
            container.addArrangedSubview(makeSettingsSeparator())
        }
        return BoxView(subview: container).withConstraints(insets: insets)
    }
}

enum IconSwitchRowEventCode: String {
    case toggleChanged = "iconSwitchRowToggleChanged"
}

enum IconSwitchRowEventPayload {
    static let id = "id"
    static let isOn = "isOn"
}
