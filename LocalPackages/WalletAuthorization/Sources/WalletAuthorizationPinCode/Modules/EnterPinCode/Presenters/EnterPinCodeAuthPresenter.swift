
import UIKit
import DiiaMVPModule
import DiiaUIComponents

protocol EnterPinCodeAction: BasePresenter {
    func forgotPincodePressed()
    func selectNumber(number: Int)
    func removeLast()
}

final class EnterPinCodeAuthPresenter: EnterPinCodeAction {
    
    // MARK: - Properties
    unowned var view: EnterPinCodeView
    private let viewModel: EnterPinCodeViewModel
    private let enterPinCodeDelegate: EnterPinCodeDelegate // strong reference, must live as long as EnterPinCodeAuthPresenter itself
    
    private let storage: PinCodeStorageProtocol
    private var pinCode: [Int] = [] {
        didSet {
            view.setEnteredNumbersCount(count: pinCode.count)
        }
    }

    // MARK: - Init
    init(
        context: EnterPinCodeModuleContext,
        view: EnterPinCodeView,
        viewModel: EnterPinCodeViewModel
    ) {
        self.storage = context.storage
        self.view = view
        self.viewModel = viewModel
        
        self.enterPinCodeDelegate = context.enterPinCodeDelegate
    }
    
    func configureView() {
        view.configure(with: viewModel)
    }
    
    func selectNumber(number: Int) {
        guard pinCode.count < viewModel.pinCodeLength else { return }
        pinCode.append(number)
        if pinCode.count >= viewModel.pinCodeLength {
            let incorrectCount: Int = (storage.getIncorrectPincodeAttemptsCount() ?? 0) + 1
            if enterPinCodeDelegate.checkPincode(pinCode) {
                storage.saveIncorrectPincodeAttemptsCount(0)
                enterPinCodeDelegate.didCorrectPincodeEntered(pincode: pinCode.map(String.init).joined())
            } else if incorrectCount < Constants.allowedAttempts {
                view.userDidEnterIncorrectPin()
                pinCode = []
                storage.saveIncorrectPincodeAttemptsCount(incorrectCount)
            } else {
                enterPinCodeDelegate.didAllAttemptsExhausted(in: view)
            }
        }
    }
    
    func removeLast() {
        guard !pinCode.isEmpty else { return }
        pinCode.removeLast()
    }
    
    func forgotPincodePressed() {
        enterPinCodeDelegate.onForgotPincode(in: view)
    }
}

// MARK: - Constants
extension EnterPinCodeAuthPresenter {
    private enum Constants {
        static let allowedAttempts = 3
    }
}
