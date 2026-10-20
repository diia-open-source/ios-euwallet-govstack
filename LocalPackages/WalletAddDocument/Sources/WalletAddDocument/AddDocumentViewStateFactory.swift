import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

enum AddDocumentScreenAction: String {
    case back
    case selectDocument
    case openScanQR
    case retry
}

public enum AddDocumentContentState {
    case loaded([AddDocumentItemViewData])
    case offline
}

public protocol AddDocumentViewStateFactoryProtocol {
    func make(documentTypes: [AddDocumentItemViewData]) -> DSConstructorModel
    func make(contentState: AddDocumentContentState) -> DSConstructorModel
}

public struct AddDocumentViewStateFactory: AddDocumentViewStateFactoryProtocol {
    public init() {}
    public func make(documentTypes: [AddDocumentItemViewData]) -> DSConstructorModel {
        make(contentState: .loaded(documentTypes))
    }
    
    public func make(contentState: AddDocumentContentState) -> DSConstructorModel {
        let body: [AnyCodable] = [
            makeDescriptionCard()
        ] + makeContent(contentState: contentState)

        return DSConstructorModel(
            topGroup: [
                .component(.topGroupOrg, DSTopGroupOrg(
                    titleGroupMlc: DSTopGroupMlc(
                        heroText: WalletStringKey.addDocumentTitle.localized(),
                        label: nil,
                        hideBackButton: false
                    )
                ))
            ],
            body: body
        )
    }

    private func makeContent(contentState: AddDocumentContentState) -> [AnyCodable] {
        switch contentState {
        case .loaded(let documentTypes):
            return makeLoadedContent(documentTypes: documentTypes)
        case .offline:
            return makeOfflineContent()
        }
    }
    
    private func makeLoadedContent(documentTypes: [AddDocumentItemViewData]) -> [AnyCodable] {
        guard !documentTypes.isEmpty else {
            return [
                makeChooseFromListTitle(),
                .component(.stubInfoMessageMlc, DSEmptyStateMlc(
                    componentId: "add_document_empty_state",
                    iconAtm: DSIconModel(.attentionBlackRoundSmall),
                    title: WalletStringKey.addDocumentEmptyTitle.localized(),
                    text: WalletStringKey.addDocumentEmptyDescription.localized()
                ))
            ]
        }

        return [
            makeChooseFromListTitle()
        ] + documentTypes.enumerated().map { index, documentType -> AnyCodable in
            let rowKey = documentType.rowKey
            return makeCardComponent(
                DSCardMlcV2Model(
                    componentId: rowKey,
                    chipStatusAtm: nil,
                    label: documentType.name,
                    rightLabel: nil,
                    descriptions: documentType.description.isEmpty ? nil : [documentType.description],
                    rows: nil,
                    chips: nil,
                    iconUrlAtm: nil,
                    smallIconAtm: DSIconModel(
                        code: "ellipseArrowRight",
                        action: DSActionParameter(
                            action: AddDocumentScreenAction.selectDocument,
                            resource: rowKey
                        )
                    ),
                    smallIconAtmWithStates: nil,
                    attentionIconMessageMlc: nil,
                    action: DSActionParameter(
                        action: AddDocumentScreenAction.selectDocument,
                        resource: rowKey
                    )
                ),
                top: index == 0 ? nil : .medium,
                side: .large
            )
        } + [makeBottomSpacer()]
    }

    // Extra breathing room under the last document card so it isn't flush
    // against the bottom of the scroll area.
    private func makeBottomSpacer() -> AnyCodable {
        .component(.spacerAtm, SpacerAtm(
            componentId: "add_document_bottom_spacer",
            value: .extraLarge
        ))
    }

    private func makeChooseFromListTitle() -> AnyCodable {
        .component(.sectionTitleAtm, DSTitleLabelMlc(
            label: WalletStringKey.addDocumentChooseFromList.localized(),
            componentId: nil
        ))
    }

    private func makeOfflineContent() -> [AnyCodable] {
        return [
            makeChooseFromListTitle(),
            .component(.stubMessageMlc, DSStubMessageMlc(
                icon: nil,
                title: WalletStringKey.addDocumentOfflineTitle.localized(),
                description: WalletStringKey.addDocumentOfflineDescription.localized(),
                componentId: "add_document_offline_state",
                parameters: nil,
                btnStrokeAdditionalAtm: DSButtonModel(
                    label: WalletStringKey.addDocumentOfflineRetry.localized(),
                    state: .enabled,
                    action: DSActionParameter(action: AddDocumentScreenAction.retry),
                    componentId: "add_document_offline_retry"
                )
            ))
        ]
    }

    private func makeDescriptionCard() -> AnyCodable {
        makeBackgroundWhiteComponent(
            DSBackgroundWhiteOrgModel(
                componentId: "add_document_description",
                id: nil,
                items: [
                    .component(.textLabelMlc, DSTextContainerData(
                        componentId: nil,
                        text: WalletStringKey.addDocumentDescription.localized(),
                        label: nil,
                        parameters: nil
                    ))
                ]
            ),
            top: .large,
            side: .large
        )
    }

    private func makeCardComponent(
        _ model: DSCardMlcV2Model,
        top: DSSizingType?,
        side: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(.cardMlcV2, model, top: top, side: side)
    }

    private func makeBackgroundWhiteComponent(
        _ model: DSBackgroundWhiteOrgModel,
        top: DSSizingType?,
        side: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(.backgroundWhiteOrg, model, top: top, side: side)
    }
}
