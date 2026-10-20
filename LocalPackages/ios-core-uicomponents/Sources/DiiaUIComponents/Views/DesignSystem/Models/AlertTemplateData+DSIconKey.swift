
import DiiaCommonTypes

public extension AlertTemplateData {
    /// Leading-dot convenience: `AlertTemplateData(icon: .doneBlackRound, title: ...)`.
    init(icon: DSIconKey,
         title: String,
         description: String?,
         mainButton: AlertButtonModel,
         alternativeButton: AlertButtonModel? = nil) {
        self.init(icon: icon.rawValue,
                  title: title,
                  description: description,
                  mainButton: mainButton,
                  alternativeButton: alternativeButton)
    }
}
