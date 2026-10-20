//
//  AddDocumentsService.swift
//

import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public protocol AddDocumentsServiceProtocol {
    func showAddDocuments(in view: BaseView)
}

final public class AddDocumentsService: AddDocumentsServiceProtocol {
    
    public init() { }
    
    public func showAddDocuments(in view: BaseView) {
        let actions: [[Action]] = []
        let module = ActionSheetModule(actions: actions)
        view.showChild(module: module)
    }
}
