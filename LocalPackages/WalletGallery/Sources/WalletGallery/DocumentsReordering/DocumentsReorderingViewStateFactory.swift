import Foundation
import DiiaCommonTypes
import WalletDocumentsCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public protocol DocumentsReorderingViewStateFactoryProtocol {
    func make(documents: [DocumentModel]) -> DSConstructorModel
}

public struct DocumentsReorderingViewStateFactory: DocumentsReorderingViewStateFactoryProtocol {
    public init() {}
    public func make(documents: [DocumentModel]) -> DSConstructorModel {
        DSConstructorModel(
            topGroup: [
                .component(.topGroupOrg, DSTopGroupOrg(
                    titleGroupMlc: DSTopGroupMlc(
                        leftNavIcon: DSIconModel(
                            code: "back",
                            action: DSActionParameter(action: DocumentsReorderingScreenAction.back)
                        ),
                        heroText: WalletStringKey.documentReorderingTitle.localized(),
                        hideBackButton: false
                    )
                ))
            ],
            body: documents.isEmpty ? [makeStub()] : [
                .component(
                    .documentsReorderingList,
                    DocumentsReorderingListModel(items: documents.map(makeItem))
                )
            ]
        )
    }

    private func makeStub() -> AnyCodable {
        .component(.stubMessageMlc, DSStubMessageMlc(
            icon: nil,
            title: WalletStringKey.documentReorderingStubTitle.localized(),
            description: WalletStringKey.documentReorderingStubDescription.localized(),
            componentId: nil,
            parameters: nil,
            btnStrokeAdditionalAtm: nil
        ))
    }

    private func makeItem(document: DocumentModel) -> DocumentsReorderingItemModel {
        let title = document.displayName
        let subtitle = document.issuerIdentifier.map { WalletStringKey.documentIssuer.localized(with: $0) }

        return DocumentsReorderingItemModel(
            title: title,
            subtitle: subtitle,
            dragIcon: .drag,
            dragIconAccessibilityLabel: WalletStringKey.documentsAccessibilityChangeOrderLabel
                .formattedLocalized(arguments: title),
            dragIconAccessibilityHint: WalletStringKey.documentsAccessibilityChangeOrderHint.localized()
        )
    }
}

enum DocumentsReorderingScreenAction: String {
    case back
}
