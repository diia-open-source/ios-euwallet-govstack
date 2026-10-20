//
//  DeferredDocumentViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels

public protocol DeferredDocumentViewStateFactoryProtocol {
    func make(credential: Credential) -> DSFullDocumentModel
}

/// Builds the same `DSFullDocumentModel` shape used by issued PID / MDL cards, but with deferred-only fields populated.
/// The existing `DSDocumentWithPhotoView` gracefully hides empty sections, so this surfaces a "Pending" placeholder using the standard card chrome — mirroring how the revoked / expired states reuse the same view.
public struct DeferredDocumentViewStateFactory: DeferredDocumentViewStateFactoryProtocol {
    public init() {}
    public func make(credential: Credential) -> DSFullDocumentModel {
        let displayName = displayName(for: credential)
        let frontCard = frontCardModel(
            displayName: displayName,
            issuerDisplay: credential.issuerDisplayName,
            issuerHost: credential.credentialIssuerIdentifier,
            createdAt: credential.createdAt
        )

        return DSFullDocumentModel(
            status: .ok,
            expirationDate: .distantFuture,
            data: [
                DSDocumentData(
                    docStatus: DocumentStatusCode.ok.rawValue,
                    id: credential.id,
                    docNumber: .empty,
                    content: nil,
                    docData: DSDocData(
                        docName: displayName,
                        docType: credential.docType
                    ),
                    frontCard: frontCard,
                    fullInfo: nil
                )
            ]
        )
    }

    // MARK: - Private
    private func frontCardModel(
        displayName: String,
        issuerDisplay: String?,
        issuerHost: String?,
        createdAt: Date
    ) -> DSDocumentModel {
        DSDocumentModel(
            docHeadingOrg: DSDocumentHeading(
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: displayName,
                    subtitles: nil
                )
            ),
            tableBlockPlaneOrg: DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: tableItems(issuerDisplay: issuerDisplay, issuerHost: issuerHost, createdAt: createdAt)
            ),
            subtitleLabelMlc: issuerDisplay.map { DSTitleLabelMlc(label: $0, componentId: nil) },
            docButtonHeadingOrg: DSDocumentHeading(
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: WalletStringKey.deferredDocumentPendingLabel.localized(),
                    subtitles: nil
                ),
                iconAtm: DSIconModel(
                    code: Constants.kebabIconCode,
                    action: DSActionParameter(type: Constants.kebabActionType, subtype: Constants.kebabActionSubtypeDeferred)
                )
            )
        )
    }

    private func tableItems(
        issuerDisplay: String?,
        issuerHost: String?,
        createdAt: Date
    ) -> [DSTableItem] {
        var items: [DSTableItem] = []
        if let issuerHost {
            items.append(DSTableItem(tableItemVerticalMlc: DSTableItemVerticalMlc(
                label: WalletStringKey.deferredDocumentIssuerLabel.localized(),
                value: issuerHost
            )))
        }
        items.append(DSTableItem(tableItemVerticalMlc: DSTableItemVerticalMlc(
            label: WalletStringKey.deferredDocumentInProgressLabel.localized(),
            value: Self.dateFormatter.string(from: createdAt)
        )))
        // Static estimate row — not derived from the credential, shown for every deferred doc.
        items.append(DSTableItem(tableItemVerticalMlc: DSTableItemVerticalMlc(
            label: WalletStringKey.deferredDocumentTimeToIssueLabel.localized(),
            value: WalletStringKey.deferredDocumentTimeToIssueValue.localized()
        )))
        return items
    }

    private func displayName(for credential: Credential) -> String {
        if let resolved = credential.displayName, !resolved.isEmpty {
            return resolved
        }
        if let walletType = WalletDocumentType(rawValue: credential.docType) {
            return walletType.displayName
        }
        return credential.docType
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
}

private extension DeferredDocumentViewStateFactory {
    enum Constants {
        static let kebabIconCode = "ellipseKebab"
        static let kebabActionType = "ellipseMenu"
        static let kebabActionSubtypeDeferred = "deferred"
    }
}
