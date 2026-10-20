//
//  DocumentDetailsCommonViewStateFactory.swift
//

import UIKit
import DiiaCommonTypes
import DiiaUIComponents

public struct DocumentDetailsCommonViewState {
    public let model: DSConstructorModel
    public let fabric: DSViewFabric

    public init(model: DSConstructorModel, fabric: DSViewFabric) {
        self.model = model
        self.fabric = fabric
    }
}

public protocol DocumentDetailsCommonViewStateFactoryProtocol {
    func make(
        viewModel: DocumentDetailsCommonViewModel,
        insuranceTicker: DSTickerAtom?
    ) -> DocumentDetailsCommonViewState
}

public struct DocumentDetailsCommonViewStateFactory: DocumentDetailsCommonViewStateFactoryProtocol {

    public init() {}

    public func make(
        viewModel: DocumentDetailsCommonViewModel,
        insuranceTicker: DSTickerAtom?
    ) -> DocumentDetailsCommonViewState {
        var body = viewModel.bodyModel()

        if let ticker = insuranceTicker {
            body.insert(
                .dictionary([DSTickerAtmBuilder.key: .fromEncodable(encodable: ticker)]),
                at: Constants.tickerInsertIndex
            )
        }

        return DocumentDetailsCommonViewState(
            model: DSConstructorModel(topGroup: [], body: body),
            fabric: makeFabric(images: viewModel.images)
        )
    }

    private func makeFabric(images: [DSDocumentContentData: UIImage]) -> DSViewFabric {
        let fabric = DSViewFabric()
        fabric.setBuilder(DSTableBlockTwoColumnsOrgBuilder(imagesContent: images))
        fabric.setBuilder(DSTickerAtmBuilder(padding: Constants.tickerAtmPadding))
        fabric.setBuilder(DSChipsBlackOrgBuilder(isActive: false))
        return fabric
    }
}

private extension DocumentDetailsCommonViewStateFactory {
    enum Constants {
        static let tickerInsertIndex = 1
        static let tickerAtmPadding = UIEdgeInsets(top: 24, left: .zero, bottom: .zero, right: .zero)
    }
}
