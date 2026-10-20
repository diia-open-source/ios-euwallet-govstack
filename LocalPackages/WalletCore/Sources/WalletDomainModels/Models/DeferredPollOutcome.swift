//
//  DeferredPollOutcome.swift
//

import Foundation

/// Outcome of a batch poll over all deferred documents.
public struct DeferredPollOutcome: Sendable {
    public let issuedIds: [String]
    public let failedIds: [String]
    public let stillDeferredIds: [String]

    public init(issuedIds: [String], failedIds: [String], stillDeferredIds: [String]) {
        self.issuedIds = issuedIds
        self.failedIds = failedIds
        self.stillDeferredIds = stillDeferredIds
    }
}
