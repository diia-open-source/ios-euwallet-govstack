//
//  DocumentsQRPlaceholderView.swift
//

import UIKit
import Lottie
import DiiaCommonTypes
import DiiaUIComponents

public class DocumentsQRPlaceholderView: BaseCodeView {
    public var accessibilityActivationHandler: Callback?

    // MARK: - Subviews
    private let titleLabel: UILabel = {
        let label = UILabel().withParameters(
            font: FontBook.usualFont,
            textColor: .gray,
            textAlignment: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let qrCodeView: DSQRCodeMlcView = {
        let view = DSQRCodeMlcView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init
    public override func setupSubviews() {
        backgroundColor = .white
        layer.masksToBounds = true
        layer.cornerRadius = Constants.cornerRadius
        isAccessibilityElement = true
        accessibilityTraits = .button

        addSubviews([titleLabel, qrCodeView])

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            qrCodeView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            qrCodeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            qrCodeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor)
        ])
    }

    // MARK: - Public Methods
    public func configure(title: String, link: String) {
        titleLabel.text = title
        qrCodeView.configure(for: .init(qrLink: link))
        accessibilityLabel = title
    }

    public override func accessibilityActivate() -> Bool {
        guard let accessibilityActivationHandler else { return false }
        accessibilityActivationHandler()
        return true
    }
}

// MARK: - Constants
private extension DocumentsQRPlaceholderView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
    }
}
