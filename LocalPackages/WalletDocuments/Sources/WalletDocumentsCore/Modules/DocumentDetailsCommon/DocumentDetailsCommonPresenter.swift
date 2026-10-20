//
//  DocumentDetailsCommonPresenter.swift
//

import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public final class DocumentDetailsCommonPresenter: ConstructorModalScreenPresenter {
    private unowned let view: ConstructorModalScreenViewProtocol
    private let viewModel: DocumentDetailsCommonViewModel
    private let insuranceTicker: DSTickerAtom?
    private let viewStateFactory: DocumentDetailsCommonViewStateFactoryProtocol
    private let screenBrightnessService: ScreenBrightnessServiceProtocol?

    public init(
        view: ConstructorModalScreenViewProtocol,
        viewModel: DocumentDetailsCommonViewModel,
        insuranceTicker: DSTickerAtom?,
        viewStateFactory: DocumentDetailsCommonViewStateFactoryProtocol,
        screenBrightnessService: ScreenBrightnessServiceProtocol?
    ) {
        self.view = view
        self.viewModel = viewModel
        self.insuranceTicker = insuranceTicker
        self.viewStateFactory = viewStateFactory
        self.screenBrightnessService = screenBrightnessService
    }

    deinit {
        screenBrightnessService?.resetBrightness()
    }

    public var hasCloseButton: Bool { false }

    public func configureView() {
        let state = viewStateFactory.make(viewModel: viewModel, insuranceTicker: insuranceTicker)
        view.setFabric(state.fabric)
        view.configure(model: state.model)
    }

    public func handleEvent(event: ConstructorItemEvent) {
        viewModel.eventHandler?.handleEvent(event: event)
    }
}
