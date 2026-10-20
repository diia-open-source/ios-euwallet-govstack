//
//  TransactionStatusMapper.swift
//

import Foundation
import DiiaUIComponents
import WalletCore
import WalletDomainModels

/// Maps WalletCore's domain status to the UI's chip type.
/// Display text comes from `TransactionLogEntry.Status.displayText`; this enum stays
/// here because WalletCore can't depend on `DiiaUIComponents`.
enum TransactionStatusMapper {

    static func chipType(for status: TransactionLogEntry.Status) -> DSCardStatusChipType {
        switch status {
        case .incomplete: return .neutral
        case .failed: return .fail
        case .completed: return .success
        }
    }
}
