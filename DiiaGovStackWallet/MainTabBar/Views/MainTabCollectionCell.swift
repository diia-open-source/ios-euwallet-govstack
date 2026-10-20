import UIKit
import DiiaUIComponents

struct SelectableIconTitleViewModel {
    let iconName: String
    let title: String
    let selectedIconName: String
}

class MainTabCollectionCell: BaseCollectionNibCell {

    // MARK: - Views
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontBook.tabBarTitle
        label.textColor = .white
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.isUserInteractionEnabled = false
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Constants.stackSpacing
        return stack
    }()

    private var iconViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Properties
    private var vm: SelectableIconTitleViewModel?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupLayout() {
        contentView.addSubview(stackView)

        iconViewHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: Constants.iconHeight)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.stackTopInset),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            iconViewHeightConstraint
        ])
    }

    private func setupAccessibility() {
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
    }

    // MARK: - Public Methods
    func setSelected(isSelected: Bool) {
        guard let vm = vm else { return }
        let imageName = isSelected ? vm.selectedIconName : vm.iconName
        iconView.image = UIImage(named: imageName)
    }

    func configureAccessibility(isSelected: Bool, currentValue: Int, totalValue: Int, haveUnreadItem: Bool?) {
        guard let viewModel = vm else { return }
        self.accessibilityLabel = viewModel.title
        let haveUpdatesHint = haveUnreadItem ?? false ? "\(R.Strings.main_screen_accessibility_bottom_bar_cell_have_updates.localized()) " : ""
        self.accessibilityHint = haveUpdatesHint
        self.accessibilityTraits = isSelected ? [.button, .selected] : .button
    }

    func configure(with viewModel: SelectableIconTitleViewModel) {
        vm = viewModel
        titleLabel.setTextWithCurrentAttributes(text: viewModel.title)
        iconView.image = UIImage(named: viewModel.iconName)
    }
}

// MARK: - Constants
extension MainTabCollectionCell {
    private enum Constants {
        static let stackSpacing: CGFloat = 3
        static let stackTopInset: CGFloat = 16

        static var iconHeight: CGFloat {
            switch UIScreen.main.bounds.width {
            case 414, 428, 430: return 26
            default: return 24
            }
        }
    }
}
