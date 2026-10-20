import Foundation
import DiiaCommonTypes

/// Type-safe descriptor that ties a DSViewFabric builder key to its expected model type.
/// Keys are sourced from the builder's `static let key`.
public struct DSComponent<Model: Encodable> {
    public let key: String

    public init(key: String) { self.key = key }
}

public extension AnyCodable {
    static func component<M: Encodable>(_ descriptor: DSComponent<M>, _ model: M) -> AnyCodable {
        .dictionary([descriptor.key: .fromEncodable(encodable: model)])
    }

    static func component<M: Encodable>(key: String, model: M) -> AnyCodable {
        .dictionary([key: .fromEncodable(encodable: model)])
    }

    static func componentWithPadding<M: Encodable>(
        _ descriptor: DSComponent<M>,
        _ model: M,
        top: DSSizingType? = nil,
        side: DSSizingType? = nil
    ) -> AnyCodable {
        .dictionary([
            descriptor.key: withPadding(.fromEncodable(encodable: model), top: top, side: side)
        ])
    }

    static func componentWithPadding<M: Encodable>(
        key: String,
        model: M,
        top: DSSizingType? = nil,
        side: DSSizingType? = nil
    ) -> AnyCodable {
        .dictionary([
            key: withPadding(.fromEncodable(encodable: model), top: top, side: side)
        ])
    }

    private static func withPadding(
        _ value: AnyCodable,
        top: DSSizingType? = nil,
        side: DSSizingType? = nil
    ) -> AnyCodable {
        guard case .dictionary(var dict) = value else { return value }
        dict["paddingMode"] = .fromEncodable(encodable: DSPaddingsModel(top: top, side: side))
        return .dictionary(dict)
    }
}

// MARK: - Built-in descriptors

public extension DSComponent where Model == DSDocumentHeading {
    static var docHeadingOrg: Self { .init(key: DSDocHeadingBuilder.key) }
}

public extension DSComponent where Model == DSTickerAtom {
    static var tickerAtm: Self { .init(key: DSTickerAtmBuilder.key) }
}

public extension DSComponent where Model == DSTableBlockTwoColumnPlaneOrg {
    static var tableBlockTwoColumnsOrg: Self { .init(key: DSTableBlockTwoColumnsOrgBuilder.key) }
}

public extension DSComponent where Model == DSTableBlockItemModel {
    static var tableBlockOrg: Self { .init(key: DSTableBlockOrgBuilder.key) }
}

public extension DSComponent where Model == DSCardMlcV2Model {
    static var cardMlcV2: Self { .init(key: DSCardMlcV2Builder.key) }
}

public extension DSComponent where Model == DSStubMessageMlc {
    static var stubMessageMlc: Self { .init(key: DSStubMessageMlcViewBuilder.key) }
}

public extension DSComponent where Model == DSEmptyStateMlc {
    static var stubInfoMessageMlc: Self { .init(key: DSStubInfoMessageMlcViewBuilder.key) }
}

public extension DSComponent where Model == DSListGroup {
    static var listItemGroupOrg: Self { .init(key: DSListViewBuilder.key) }
}

public extension DSComponent where Model == DSListGroupItem {
    static var listItemMlc: Self { .init(key: DSListItemMlcBuilder.key) }
}

public extension DSComponent where Model == SpacerAtm {
    static var spacerAtm: Self { .init(key: SpacerBuilder.key) }
}

public extension DSComponent where Model == DSTopGroupOrg {
    static var topGroupOrg: Self { .init(key: DSTopGroupViewBuilder.key) }
}

public extension DSComponent where Model == DSTitleLabelMlc {
    static var titleLabelMlc: Self { .init(key: DSTitleLabelBuilder.key) }
    static var sectionTitleAtm: Self { .init(key: DSSectionTitleBuilder.key) }
}

public extension DSComponent where Model == DSBottomGroupOrg {
    static var bottomGroupOrg: Self { .init(key: DSBottomGroupBuilder.key) }
}

public extension DSComponent where Model == DSBackgroundWhiteOrgModel {
    static var backgroundWhiteOrg: Self { .init(key: DSBackgroundWhiteViewBuilder.key) }
}

public extension DSComponent where Model == DSTableHeadingItemModel {
    static var tableSecondaryHeadingMlc: Self { .init(key: TableSecondaryHeadingBuilder.key) }
    static var tableMainHeadingMlc: Self { .init(key: DSTableMainHeadingBuilder.key) }
}

public extension DSComponent where Model == DSButtonModel {
    static var btnPrimaryDefaultAtm: Self { .init(key: DSPrimaryButtonBuilder.key) }
}

public extension DSComponent where Model == DSTableItemCheckboxModel {
    static var tableItemCheckboxMlc: Self { .init(key: DSTableItemCheckboxViewBuilder.key) }
}

public extension DSComponent where Model == DSNavigationPanelV2 {
    static var navigationPanelMlcV2: Self { .init(key: DSNavigationPanelMlcV2Builder.key) }
}

public extension DSComponent where Model == DSTextBlockV2Model {
    static var tableBlockOrgV2: Self { .init(key: DSTableBlockOrgV2Builder.key) }
}

public extension DSComponent where Model == DSTextContainerData {
    static var textLabelMlc: Self { .init(key: DSTextLabelBuilder.key) }
}

public extension DSComponent where Model == DSAccordionOrgModel {
    static var accordionOrg: Self { .init(key: DSAccordionOrgBuilder.key) }
}

public extension DSComponent where Model == DSTableItemHorizontalMlc {
    static var tableItemHorizontalMlc: Self { .init(key: DSTableItemHorizontalMlcBuilder.key) }
}

// MARK: - DSActionParameter convenience

public extension DSActionParameter {
    init<A: RawRepresentable>(action: A, resource: String? = nil) where A.RawValue == String {
        self.init(type: action.rawValue, resource: resource)
    }
}
