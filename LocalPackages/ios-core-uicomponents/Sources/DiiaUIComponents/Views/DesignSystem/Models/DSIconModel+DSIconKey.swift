
import Foundation

public extension DSIconModel {
    /// Leading-dot convenience: `DSIconModel(.back, action: ...)`.
    init(_ icon: DSIconKey,
         accessibilityDescription: String? = nil,
         componentId: String? = nil,
         action: DSActionParameter? = nil,
         isEnable: Bool = true) {
        self.init(code: icon.rawValue,
                  accessibilityDescription: accessibilityDescription,
                  componentId: componentId,
                  action: action,
                  isEnable: isEnable)
    }
}
