import UIKit
import DiiaMVPModule
import DiiaUIComponents

protocol BiometrySetupView: BaseView {
    func configure(with viewModel: BiometrySetupViewModel)
    func showError(message: String)
}

final class BiometrySetupViewController: UIViewController {

    // MARK: - Properties
    var presenter: BiometrySetupAction!

    // MARK: - UI Elements
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = R.Image.light_background.image
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.largeFont
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.bigText
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        return imageView
    }()

    private lazy var allowButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = FontBook.bigText
        button.layer.cornerRadius = 24
        button.setTitle(R.Strings.biometry_setup_allow.localized(), for: .normal)
        button.addTarget(self, action: #selector(allowButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var maybeLaterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = FontBook.bigText
        button.setTitle(R.Strings.biometry_setup_maybe_later.localized(), for: .normal)
        button.addTarget(self, action: #selector(maybeLaterButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
        presenter.configureView()
    }

    override func canGoBack() -> Bool {
        return false
    }

    // MARK: - Private Methods
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(iconImageView)
        view.addSubview(allowButton)
        view.addSubview(maybeLaterButton)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            allowButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            allowButton.widthAnchor.constraint(equalToConstant: 160),
            allowButton.bottomAnchor.constraint(equalTo: maybeLaterButton.topAnchor, constant: -16),
            allowButton.heightAnchor.constraint(equalToConstant: 48),

            maybeLaterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            maybeLaterButton.widthAnchor.constraint(equalToConstant: 160),
            maybeLaterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            maybeLaterButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        iconImageView.isAccessibilityElement = false
        allowButton.accessibilityTraits = .button
        maybeLaterButton.accessibilityTraits = .button
    }

    // MARK: - Actions
    @objc private func allowButtonTapped() {
        presenter.allowTapped()
    }

    @objc private func maybeLaterButtonTapped() {
        presenter.maybeLaterTapped()
    }
}

// MARK: - BiometrySetupView
extension BiometrySetupViewController: BiometrySetupView {
    func configure(with viewModel: BiometrySetupViewModel) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        iconImageView.image = viewModel.icon
    }

    func showError(message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.Strings.general_ok.localized(), style: .default))
        present(alert, animated: true)
    }
}
