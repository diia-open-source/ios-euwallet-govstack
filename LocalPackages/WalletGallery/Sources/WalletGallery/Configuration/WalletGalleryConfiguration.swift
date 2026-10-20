import UIKit

/// Deployment-supplied UIImages used by the gallery's card-action menu (info, delete).
///
/// Each wallet deployment ships its own icon set; the gallery package only knows them
/// by purpose. Defaults are `nil`, which yields a text-only menu entry.
public struct WalletGalleryImages {
    public let documentInfo: UIImage?
    public let deleteDocument: UIImage?

    public init(documentInfo: UIImage? = nil, deleteDocument: UIImage? = nil) {
        self.documentInfo = documentInfo
        self.deleteDocument = deleteDocument
    }
}

/// Global access point for the gallery package's deployment-specific configuration.
///
/// Configured once at app launch (next to `WalletDependencies.configure(...)`).
/// Reading before configuration returns an all-`nil` `WalletGalleryImages`,
/// which yields a text-only action menu — safe but visually plain.
public enum WalletGalleryConfiguration {
    public static func configure(images: WalletGalleryImages) {
        _images = images
    }

    public static var images: WalletGalleryImages {
        return _images ?? WalletGalleryImages()
    }

    private static var _images: WalletGalleryImages?
}
