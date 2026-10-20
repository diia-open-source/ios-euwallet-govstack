//
//  DocClaimsDecodable+Ext.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import MdocDataModel18013

extension DocClaimsDecodable {
    static func getCborItemValue<T>(_ nameSpaceItems: [NameSpace: [IssuerSignedItem]], string name: String) -> T? {
        for (_, v) in nameSpaceItems {
            if let item = v.first(where: { name == $0.elementIdentifier }) {
                return item.getTypedValue()
            }
        }
        return nil
    }
}
