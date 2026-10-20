import UIKit

public struct BiometrySetupViewModel {
    let title: String
    let description: String
    let icon: UIImage?

    public init(title: String, description: String, icon: UIImage?) {
        self.title = title
        self.description = description
        self.icon = icon
    }
}
