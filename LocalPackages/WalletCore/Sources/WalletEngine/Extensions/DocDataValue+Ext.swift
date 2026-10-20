//
//  DocDataValue+Ext.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import MdocDataModel18013

extension DocDataValue {
    func getValue<T>() -> T? {
        switch self {
        case .boolean(let value as T): return value
        case .integer(let value as T): return value
        case .double(let value as T): return value
        case .string(let value as T): return value
        case .date(let value as T): return value
        case .bytes(let value as T): return value
        default: return nil
        }
    }
}
