
import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes

protocol EnterPinCodeView: BaseView {
    func configure(with viewModel: EnterPinCodeViewModel)
	func setEnteredNumbersCount(count: Int)
    func userDidEnterIncorrectPin()
    func setupBackground(_ background: ConstructorBackground)
    func configureAdditionalButton(image: UIImage?, accessibilityLabel: String?, accessibilityHint: String?, action: @escaping () -> Void)
}

final class EnterPinCodeViewController: UIViewController, Storyboarded, ChildSubcontroller {

    // MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pincodeView: PincodeView!
    @IBOutlet private weak var forgotButton: UIButton!
    
    @IBOutlet private weak var pincodeHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pincodeBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var forgotBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    var presenter: EnterPinCodeAction!
    weak var container: ContainerProtocol?
    
	// MARK: - Lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.configureView()
        pincodeView.delegate = self
        
        titleLabel.font = FontBook.detailsTitleFont
        pincodeHeightConstraint.constant = Constants.pincodeHeight
        pincodeBottomConstraint.constant = Constants.pincodeBottomOffset
        forgotBottomConstraint.constant = Constants.forgetBottomOffset
        
        forgotButton.titleLabel?.font = FontBook.usualFont
    }
    
    private func setupAccessibility() {
        titleLabel.accessibilityIdentifier = Constants.titleComponentId
        pincodeView.accessibilityIdentifier = Constants.numButtonTitleComponentId
        pincodeView.setComponentIds(
            indicatorsId: Constants.ellipsStepperComponentId,
            buttonsTile: Constants.btnNumComponentId)
    }
    
    // MARK: - Overriding
    override func canGoBack() -> Bool {
        return false
    }
    
    // MARK: - Actions
    @IBAction private func forgetBtnPressed(_ sender: Any) {
        presenter.forgotPincodePressed()
    }
}

// MARK: - View logic
extension EnterPinCodeViewController: EnterPinCodeView {

    func configure(with viewModel: EnterPinCodeViewModel) {
        pincodeView.indicatorsAmount = viewModel.pinCodeLength
        titleLabel.text = viewModel.title
        forgotButton.setTitle(viewModel.forgotTitle, for: .normal)
    }
    
    func userDidEnterIncorrectPin() {
        pincodeView.notifyIncorrectPincode()
    }
    
    func setEnteredNumbersCount(count: Int) {
        pincodeView.setNumbersCount(count: count)
    }
    
    func configureAdditionalButton(image: UIImage?, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        pincodeView.configureAdditionalButton(image: image, accessibilityLabel: accessibilityLabel, accessibilityHint: accessibilityHint, action: action)
    }

    public func setupBackground(_ background: ConstructorBackground) {
        switch background {
        case .color(let color):
            backgroundImageView.image = UIImage.from(color: color)
        case .image(let image):
            backgroundImageView.image = image
        }
    }
}

// MARK: - PinCodeViewDelegate
extension EnterPinCodeViewController: PinCodeViewDelegate {
    func numberSelected(number: Int) {
        presenter.selectNumber(number: number)
    }
    
    func clearPressed() {
        presenter.removeLast()
    }
}

extension EnterPinCodeViewController {
    private enum Constants {
        static var pincodeHeight: CGFloat {
            switch UIDevice.size() {
            case .screen4Inch, .screen_zoomed: return 372
            case .screen5_5Inch, .screen6_1Inch: return 480
            case .screen6_5Inch, .screen6_7Inch: return 640
            default: return 436
            }
        }
        
        static var pincodeBottomOffset: CGFloat {
            switch UIDevice.size() {
            case .screen4Inch, .screen_zoomed: return 27
            case .screen5_5Inch, .screen6_1Inch: return 50
            case .screen6_5Inch, .screen6_7Inch: return -24
            default: return 33
            }
        }
        
        static var forgetBottomOffset: CGFloat {
            switch UIDevice.size() {
            case .screen4Inch, .screen_zoomed: return 12
            case .screen5_5Inch, .screen6_1Inch: return 19
            case .screen6_5Inch, .screen6_7Inch: return 16
            default: return 16
            }
        }

        static let titleComponentId = "title_pinenter"
        static let numButtonTitleComponentId = "num_button_title_pinenter"
        static let ellipsStepperComponentId = "ellips_stepper_pincreate"
        static let btnNumComponentId = "btn_num_pincreate"
    }
}
