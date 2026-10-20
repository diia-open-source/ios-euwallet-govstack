//
//  WalletCredentialStoringResult.swift
//

import Foundation

public struct WalletCredentialStoringResult: Codable {
    let event: WalletCredentialStoringEvent
    let notificationId: String
    let eventDescription: String?
    
    public init(
        event: WalletCredentialStoringEvent,
        notificationId: String,
        eventDescription: String? = nil
    ) {
        self.event = event
        self.eventDescription = eventDescription
        self.notificationId = notificationId
    }
}

public enum WalletCredentialStoringEvent: String, Codable {
    case credentialAccepted
    case credentialDeleted
    case credentialFailure
}
