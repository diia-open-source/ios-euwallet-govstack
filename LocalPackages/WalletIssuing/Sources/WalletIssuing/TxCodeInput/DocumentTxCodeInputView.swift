//
//  DocumentTxCodeInputView.swift
//

import UIKit
import DiiaUIComponents
import WalletCore
import WalletDomainModels

final class DocumentTxCodeInputView: UIViewController {

    // MARK: - Properties
    private var hasSubmitted = false
    private let doneButtonViewModel = DSLoadingButtonViewModel(
        title: WalletStringKey.transactionCodeDone.localized(),
        state: .disabled
    )
    var presenter: DocumentTxCodeInputAction!
    
    // MARK: - Subviews
    private lazy var navigationView: TopNavigationView = {
        let view = TopNavigationView()
        view.setupTitle(title: nil)
        view.setupOnClose(callback: { [weak self] in
            self?.closeButtonTapped()
        })
        view.setupOnContext(callback: nil)
        return view
    }()

    private lazy var screenTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.usualFont.withSize(Constants.titleFontSize)
        label.textColor = .black
        label.textAlignment = .center
        label.text = WalletStringKey.transactionCodeScreenTitle.localized()
        return label
    }()
    
    private lazy var descriptionCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.cardCornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.usualFont.withSize(Constants.descriptionFontSize)
        label.textColor = .black
        label.numberOfLines = 0
        label.text = WalletStringKey.transactionCodeInputTitle.localized()
        return label
    }()
    
    private lazy var codeInputView: TitledTextFieldViewV2 = {
        let view = TitledTextFieldViewV2()
        view.configure(
            viewModel: TitledTextFieldViewModel(
                title: WalletStringKey.transactionCodeFieldLabel.localized(),
                placeholder: WalletStringKey.transactionCodeFieldPlaceholder.localized(),
                keyboardType: presenter.isNumericInput ? .numberPad : .default,
                onChangeText: { [weak self] value in
                    self?.presenter.handleInputChanged(value)
                    self?.updateDoneButtonState(for: value)
                }
            )
        )
        view.textField.textContentType = .oneTimeCode
        view.textField.returnKeyType = .done
        view.setupUI(textFont: FontBook.usualFont)
        return view
    }()

    private lazy var inputCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.cardCornerRadius
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var doneButton: DSPrimaryDefaultButton = {
        let button = DSPrimaryDefaultButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = FontBook.bigText
        doneButtonViewModel.callback = { [weak self] in
            self?.submit()
        }
        button.configure(viewModel: doneButtonViewModel)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Private Methods
    private func setupSubviews() {
        view.backgroundColor = Constants.backgroundColor
        view.addSubviews([navigationView, screenTitleLabel, descriptionCard, inputCard, doneButton])
        descriptionCard.addSubview(descriptionLabel)
        inputCard.addSubview(codeInputView)
        
        NSLayoutConstraint.activate([
            navigationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationView.heightAnchor.constraint(equalToConstant: Constants.navigationHeight),

            screenTitleLabel.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: Constants.titleTopOffset),
            screenTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            screenTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            
            descriptionCard.topAnchor.constraint(equalTo: screenTitleLabel.bottomAnchor, constant: Constants.contentTopOffset),
            descriptionCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            descriptionCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            
            descriptionLabel.topAnchor.constraint(equalTo: descriptionCard.topAnchor, constant: Constants.cardVerticalInset),
            descriptionLabel.leadingAnchor.constraint(equalTo: descriptionCard.leadingAnchor, constant: Constants.cardHorizontalInset),
            descriptionLabel.bottomAnchor.constraint(equalTo: descriptionCard.bottomAnchor, constant: -Constants.cardVerticalInset),
            descriptionLabel.trailingAnchor.constraint(equalTo: descriptionCard.trailingAnchor, constant: -Constants.cardHorizontalInset),
            
            inputCard.topAnchor.constraint(equalTo: descriptionCard.bottomAnchor, constant: Constants.inputTopOffset),
            inputCard.leadingAnchor.constraint(equalTo: descriptionCard.leadingAnchor),
            inputCard.trailingAnchor.constraint(equalTo: descriptionCard.trailingAnchor),
            inputCard.heightAnchor.constraint(equalToConstant: Constants.inputCardHeight),

            codeInputView.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: Constants.inputCardVerticalInset),
            codeInputView.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: Constants.inputCardHorizontalInset),
            codeInputView.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor, constant: -Constants.inputCardVerticalInset),
            codeInputView.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -Constants.inputCardHorizontalInset),

            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: Constants.buttonWidth),
            doneButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -Constants.buttonBottomOffset),
            doneButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    private func updateDoneButtonState(for value: String) {
        guard !hasSubmitted else { return }
        doneButtonViewModel.state.value = presenter.isComplete(presenter.normalized(value)) ? .enabled : .disabled
    }

    private func submit() {
        guard !hasSubmitted else { return }
        let currentValue = codeInputView.textField.text ?? ""
        presenter.handleSubmitAction(txCode: currentValue)
        if presenter.isComplete(presenter.normalized(currentValue)) {
            hasSubmitted = true
            doneButtonViewModel.state.value = .loading
            codeInputView.textField.resignFirstResponder()
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        codeInputView.textField.resignFirstResponder()
        presenter.handleCloseAction()
    }
}

// MARK: - DocumentTxCodeInputViewProtocol
extension DocumentTxCodeInputView: DocumentTxCodeInputViewProtocol {
    func updateInput(_ value: String) {
        if codeInputView.textField.text != value {
            codeInputView.textField.text = value
        }
        updateDoneButtonState(for: value)
    }

    func close() {
        dismiss(animated: true)
    }
}

// MARK: - Constants
extension DocumentTxCodeInputView {
    private enum Constants {
        static let backgroundColor = UIColor.blackSqueeze
        static let titleFontSize: CGFloat = 21
        static let descriptionFontSize: CGFloat = 16
        static let navigationHeight: CGFloat = 56
        static let horizontalInset: CGFloat = 16
        static let titleTopOffset: CGFloat = 8
        static let contentTopOffset: CGFloat = 24
        static let inputTopOffset: CGFloat = 20
        static let inputCardHeight: CGFloat = 92
        static let cardCornerRadius: CGFloat = 12
        static let cardHorizontalInset: CGFloat = 16
        static let cardVerticalInset: CGFloat = 16
        static let inputCardHorizontalInset: CGFloat = 16
        static let inputCardVerticalInset: CGFloat = 16
        static let buttonWidth: CGFloat = 160
        static let buttonBottomOffset: CGFloat = 28
        static let buttonHeight: CGFloat = 48
    }
}
