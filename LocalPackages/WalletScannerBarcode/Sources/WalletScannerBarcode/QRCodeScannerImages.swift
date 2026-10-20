import UIKit

public struct QRCodeScannerImages {
    public let backButton: UIImage?
    public let leftTopCorner: UIImage?
    public let leftBottomCorner: UIImage?
    public let rightTopCorner: UIImage?
    public let rightBottomCorner: UIImage?

    public init(
        backButton: UIImage? = nil,
        leftTopCorner: UIImage? = nil,
        leftBottomCorner: UIImage? = nil,
        rightTopCorner: UIImage? = nil,
        rightBottomCorner: UIImage? = nil
    ) {
        self.backButton = backButton
        self.leftTopCorner = leftTopCorner
        self.leftBottomCorner = leftBottomCorner
        self.rightTopCorner = rightTopCorner
        self.rightBottomCorner = rightBottomCorner
    }
}
