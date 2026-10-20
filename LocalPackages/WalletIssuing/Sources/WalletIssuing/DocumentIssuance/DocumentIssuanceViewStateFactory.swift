//
//  DocumentIssuanceViewStateFactory.swift
//

import UIKit
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

// MARK: - Action Types

enum DocumentIssuanceScreenAction: String {
    case back
    case issueDocument
    case dismiss
}

// MARK: - Factory

public protocol DocumentIssuanceViewStateFactoryProtocol {
    func make(offer: IssuanceOffer) -> DSConstructorModel
}

public struct DocumentIssuanceViewStateFactory: DocumentIssuanceViewStateFactoryProtocol {
    public init() {}

    public func make(offer: IssuanceOffer) -> DSConstructorModel {
        let body: [AnyCodable] = offer.documents.reduce(into: [
            .component(.titleLabelMlc, DSTitleLabelMlc(
                label: WalletStringKey.issuanceScreenSubtitle.localized(),
                componentId: nil
            )),
            .component(.eudiIssuanceDescriptionCard, IssuanceDescriptionCardModel(
                componentId: nil,
                text: WalletStringKey.issuanceScreenDescription.localized()
            ))
        ]) { partialResult, docModel in
            partialResult.append(makeDocSection(displayName: docModel.displayName))
        }

        return DSConstructorModel(
            topGroup: [
                .component(.navigationPanelMlcV2, DSNavigationPanelV2(
                    componentId: nil,
                    title: WalletStringKey.issuanceScreenTitle.localized(),
                    iconLeft: DSIconModel(
                        code: "back",
                        action: DSActionParameter(action: DocumentIssuanceScreenAction.back)
                    ),
                    isClosed: true
                ))
            ],
            body: body,
            bottomGroup: [
                .component(.bottomGroupOrg, DSBottomGroupOrg(
                    componentId: nil,
                    checkboxBtnOrg: nil,
                    btnPrimaryDefaultAtm: DSButtonModel(
                        label: WalletStringKey.issuanceScreenButtonAdd.localized(),
                        action: DSActionParameter(action: DocumentIssuanceScreenAction.issueDocument),
                        componentId: nil
                    ),
                    btnPlainAtm: DSButtonModel(
                        label: WalletStringKey.issuanceScreenButtonCancel.localized(),
                        action: DSActionParameter(action: DocumentIssuanceScreenAction.dismiss),
                        componentId: nil
                    ),
                    btnStrokeDefaultAtm: nil,
                    btnLoadIconPlainGroupMlc: nil,
                    btnPrimaryLargeAtm: nil
                ))
            ]
        )
    }

    private func makeDocSection(displayName: String) -> AnyCodable {
        .component(.backgroundWhiteOrg, DSBackgroundWhiteOrgModel(
            componentId: nil,
            id: "",
            items: [
                .component(.tableSecondaryHeadingMlc, DSTableHeadingItemModel(
                    label: displayName,
                    description: nil
                ))
            ]
        ))
    }
}

public struct IssuanceDescriptionCardModel: Codable {
    public let componentId: String?
    public let text: String

    public init(componentId: String?, text: String) {
        self.componentId = componentId
        self.text = text
    }
}

public struct IssuanceDescriptionCardBuilder: DSViewBuilderProtocol {
    public static let key = "eudiIssuanceDescriptionCard"

    public init() {}

    public func makeView(
        from object: AnyCodable,
        withPadding paddingType: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: IssuanceDescriptionCardModel = object.parseValue(forKey: Self.key) else { return nil }
        let view = IssuanceDescriptionCardView(model: model)
        return BoxView(subview: view).withConstraints(insets: Constants.insets)
    }

    private enum Constants {
        static let insets = UIEdgeInsets(top: 24, left: 24, bottom: 0, right: 24)
    }
}

private final class IssuanceDescriptionCardView: UIView {
    private let label = UILabel()

    init(model: IssuanceDescriptionCardModel) {
        super.init(frame: .zero)
        setupUI(model: model)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setupUI(model: IssuanceDescriptionCardModel) {
        backgroundColor = .white
        layer.cornerRadius = Constants.cornerRadius
        layer.masksToBounds = true
        accessibilityIdentifier = model.componentId

        label.font = FontBook.mainFont.regular.size(Constants.fontSize)
        label.textColor = .black
        label.numberOfLines = 0
        label.text = model.text
    }

    private func setupLayout() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalInset),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalInset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.verticalInset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalInset)
        ])
    }

    private enum Constants {
        static let fontSize: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
    }
}
