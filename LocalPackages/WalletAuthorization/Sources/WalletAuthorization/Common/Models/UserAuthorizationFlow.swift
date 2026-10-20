
import Foundation
import DiiaMVPModule
import DiiaCommonTypes

public typealias UserAuthorizationFlowCompletion = (BaseView?, AlertTemplateAction?) -> Void

public enum UserAuthorizationFlow {
    case login(completionHandler: UserAuthorizationFlowCompletion)
    
    func onCompletion(in view: BaseView? = nil, action: AlertTemplateAction? = nil) {
        switch self {
        case .login(let callback): callback(view, action)
        }
    }
}
