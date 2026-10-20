import UIKit
import DiiaCommonTypes
import DiiaUIComponents

struct SettingsActionRowModel: Codable {
    let componentId: String?
    let title: String
    let iconName: String
    let action: DSActionParameter?
    let showSeparator: Bool
}

struct SettingsActionRowBuilder: DSViewBuilderProtocol {
    static let key = "settingsActionRow"

    func makeView(
        from object: AnyCodable,
        withPadding padding: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: SettingsActionRowModel = object.parseValue(forKey: Self.key) else { return nil }

        let imageProvider = UIComponentsConfiguration.shared.imageProvider
        let viewModel = DSListItemViewModel(
            leftSmallIcon: imageProvider.imageForCode(imageCode: model.iconName),
            title: model.title,
            componentId: model.componentId,
            onClick: {
                guard let action = model.action else { return }
                eventHandler(.action(action))
            }
        )

        let view = DSListItemView()
        view.configure(viewModel: viewModel)
        view.setupUI(stackPadding: .init(top: 16, left: 16, bottom: 16, right: 16))

        let container = UIStackView()
        container.axis = .vertical
        container.addArrangedSubview(view)
        if model.showSeparator {
            container.addArrangedSubview(makeSettingsSeparator())
        }
        return BoxView(subview: container).withConstraints(insets: .init(top: 0, left: 16, bottom: 0, right: 16))
    }
}

/// Builds a hairline divider for the settings rows.
/// `DSSeparatorView`'s own color is `#E2ECF4`, which is the same as the screen's `blackSqueeze` background and would be invisible, so we recolor it to the design-system on-background separator color.
func makeSettingsSeparator() -> DSSeparatorView {
    let separator = DSSeparatorView()
    separator.backgroundColor = UIColor(DSConstants.Colors.separatorColor)
    return separator
}
