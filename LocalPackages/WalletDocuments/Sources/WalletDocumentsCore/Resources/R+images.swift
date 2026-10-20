
import UIKit

internal enum R {
    enum Image: String, CaseIterable {
        case pidActivationImage
        case backCardSkeleton
        case imagePlusBlack
        case changeOrder
        case menu_back
        case ds_stack
        case pidActivationImageEnglish
        
        var image: UIImage? {
            return UIImage(named: rawValue, in: Bundle.module, compatibleWith: nil)
        }
        
        var name: String {
            return rawValue
        }
    }
}
