
import Foundation

/// Type-safe identifier for a DS icon-code consumed by `DSImageNameProvider`.
///
/// `rawValue` is the unprefixed icon code passed into `DSIconModel.code` / `AlertTemplateData.icon`.
/// At resolve time `DSImageNameResolver` prepends `"DS_"` and reads from `Bundle.module`,
/// so every case must correspond to a `DS_<rawValue>` asset shipped in DiiaUIComponents.
/// Asset coverage is verified by `DSIconKeyTests.test_everyDSIconKeyResolvesToBundledAsset`.
public enum DSIconKey: String, Codable, Sendable, CaseIterable {
    case attentionBlackRound
    case attentionBlackRoundSmall
    case back
    case chevronDown
    case chevronUp
    case doneBlackRound
    case drag
    case history
    case qrScan
    case settings
}
