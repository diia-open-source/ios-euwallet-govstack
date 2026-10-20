
import DiiaCommonTypes

public struct DSAccordionOrgExpandedContentModel: Codable {
    public let items: [AnyCodable]

    public init(items: [AnyCodable]) {
        self.items = items
    }
}

public struct DSAccordionOrgModel: Codable {
    public let componentId: String?
    public let heading: String
    public let description: String?
    public let states: DSAccordionOrgState
    public let expandedContent: DSAccordionOrgExpandedContentModel?

    public init(componentId: String? = nil,
                heading: String,
                description: String? = nil,
                states: DSAccordionOrgState,
                expandedContent: DSAccordionOrgExpandedContentModel? = nil) {
        self.componentId = componentId
        self.heading = heading
        self.description = description
        self.states = states
        self.expandedContent = expandedContent
    }
}

public struct DSAccordionOrgState: Codable {
    public let isExpanded: Bool?
    public let expandedIcon: DSIconModel?
    public let collapsedIcon: DSIconModel?

    public init(isExpanded: Bool? = nil,
                expandedIcon: DSIconModel? = nil,
                collapsedIcon: DSIconModel? = nil) {
        self.isExpanded = isExpanded
        self.expandedIcon = expandedIcon
        self.collapsedIcon = collapsedIcon
    }
}
