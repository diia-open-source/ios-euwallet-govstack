//
//  DocumentTxCodeInputPresenter.swift
//

import Foundation
import DiiaMVPModule
import WalletDomainModels

protocol DocumentTxCodeInputAction: BasePresenter {
    var isNumericInput: Bool { get }
    func normalized(_ value: String) -> String
    func isComplete(_ value: String) -> Bool
    func handleCloseAction()
    func handleInputChanged(_ value: String)
    func handleSubmitAction(txCode: String?)
}

protocol DocumentTxCodeInputViewProtocol: AnyObject {
    func updateInput(_ value: String)
    func close()
}

final class DocumentTxCodeInputPresenter: DocumentTxCodeInputAction {

    // MARK: - Properties
    unowned var view: DocumentTxCodeInputViewProtocol

    private let txCodeSpec: TxCodeSpec?
    private let onSubmit: (String) -> Void
    private let onClose: () -> Void
    private var txCode: String = .empty

    // MARK: - Init
    init(
        view: DocumentTxCodeInputViewProtocol,
        txCodeSpec: TxCodeSpec?,
        onSubmit: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.view = view
        self.txCodeSpec = txCodeSpec
        self.onSubmit = onSubmit
        self.onClose = onClose
    }

    // MARK: - Public Methods
    func configureView() {}

    var isNumericInput: Bool { txCodeSpec?.isNumeric ?? true }

    func handleCloseAction() {
        onClose()
        view.close()
    }

    func handleInputChanged(_ value: String) {
        let normalizedValue = normalized(value)
        txCode = normalizedValue
        view.updateInput(normalizedValue)
    }

    func handleSubmitAction(txCode: String?) {
        let resolvedTxCode = normalized(txCode ?? self.txCode)
        guard isComplete(resolvedTxCode) else { return }
        onSubmit(resolvedTxCode)
        view.close()
    }

    func normalized(_ value: String) -> String {
        let filtered = isNumericInput ? value.filter(\.isNumber) : value
        guard let length = txCodeSpec?.length else { return filtered }
        return String(filtered.prefix(length))
    }

    func isComplete(_ value: String) -> Bool {
        guard let length = txCodeSpec?.length else { return !value.isEmpty }
        return value.count == length
    }
}
