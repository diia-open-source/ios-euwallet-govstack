
import DiiaCommonTypes
import Foundation

public struct SpacerAtm: Codable {
    public var componentId: String?
    public var value: SpacerAtmValue
    
    public init(
        componentId: String? = nil,
        value: SpacerAtmValue
    ) {
        self.componentId = componentId
        self.value = value
    }
    
    public enum SpacerAtmValue: String, Codable, EnumDecodable {
        public static let defaultValue: SpacerAtmValue = .small
        
        case small
        case medium
        case large
        case extraLarge = "extra_large"
        
        var height: CGFloat {
            switch self {
            case .small:
                return 8
            case .medium:
                return 16
            case .large:
                return 24
            case .extraLarge:
                return 32
            }
        }
    }
}
