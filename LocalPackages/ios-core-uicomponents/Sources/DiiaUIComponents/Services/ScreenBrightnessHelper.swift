import UIKit
import DiiaCommonTypes

public final class ScreenBrightnessHelper: ScreenBrightnessServiceProtocol {

    // MARK: - Properties
    private var brightnessBeforeIncreasing: CGFloat?

    // MARK: - Singleton
    private init() { }

    public static let shared = ScreenBrightnessHelper()

    // MARK: - Public Methods
    public func increaseBrightness() {
        guard UIScreen.main.brightness != UIScreen.maxBrightness else { return }

        brightnessBeforeIncreasing = UIScreen.main.brightness
        UIScreen.main.setBrightness(to: UIScreen.maxBrightness)
    }

    public func resetBrightness() {
        if let brightness = brightnessBeforeIncreasing {
            UIScreen.main.setBrightness(to: brightness)
        }
        brightnessBeforeIncreasing = nil
    }
}
