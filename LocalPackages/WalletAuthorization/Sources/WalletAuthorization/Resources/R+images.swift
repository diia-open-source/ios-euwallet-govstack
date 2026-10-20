
import UIKit

internal enum R {
    enum Image: String, CaseIterable {
        case clear
        case loadingBar
        case light_background
        
        var image: UIImage? {
            return UIImage(named: rawValue, in: Bundle.module, compatibleWith: nil)
        }
        
        var name: String {
            return rawValue
        }
    }
}
