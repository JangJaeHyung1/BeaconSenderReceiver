//
//  ViewController.swift
//  BeaconAPITest080701
//
//  Created by jh on 6/11/25.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - UI
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "landing_title".localized
        lb.font = .preferredFont(forTextStyle: .largeTitle)
        lb.textColor = .label
        lb.adjustsFontForContentSizeCategory = true
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()

    private let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "landing_subtitle".localized
        lb.font = .preferredFont(forTextStyle: .body)
        lb.textColor = .label
        lb.numberOfLines = 0
        lb.adjustsFontForContentSizeCategory = true
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()

    private let txButton = UIButton(type: .system)
    private let rxButton = UIButton(type: .system)
    private let regButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "app_name".localized
        navigationController?.navigationBar.prefersLargeTitles = true

        // Configure buttons
        configureActionButton(
            txButton,
            title: "tx_title".localized,
            subtitle: "tx_subtitle".localized,
            symbol: "dot.radiowaves.right",
            color: .systemBlue
        )
        configureActionButton(
            rxButton,
            title: "rx_title".localized,
            subtitle: "rx_subtitle".localized,
            symbol: "antenna.radiowaves.left.and.right",
            color: .systemGreen
        )
        configureActionButton(
            regButton,
            title: "reg_title".localized,
            subtitle: "reg_subtitle".localized,
            symbol: "list.bullet.rectangle",
            color: .systemOrange
        )

        // Actions
        txButton.addTarget(self, action: #selector(goToA), for: .touchUpInside)
        rxButton.addTarget(self, action: #selector(goToB), for: .touchUpInside)
        regButton.addTarget(self, action: #selector(goToC), for: .touchUpInside)

        // Header stack
        let headerStack = UIStackView(arrangedSubviews: [subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .leading
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Buttons stack
        let buttonStack = UIStackView(arrangedSubviews: [txButton, rxButton, regButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.alignment = .fill
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        // Card container
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 0
        container.layer.borderColor = UIColor.clear.cgColor
        // Soft shadow
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 10
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.masksToBounds = false
        container.translatesAutoresizingMaskIntoConstraints = false

        // Assemble
        view.addSubview(container)
        view.addSubview(headerStack)
        container.addSubview(buttonStack)

        // Constraints
        NSLayoutConstraint.activate([
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            container.topAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -50),

            buttonStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            txButton.heightAnchor.constraint(equalToConstant: 60),
            rxButton.heightAnchor.constraint(equalTo: txButton.heightAnchor),
            regButton.heightAnchor.constraint(equalTo: txButton.heightAnchor)
        ])
    }

    // MARK: - Navigation
    @objc func goToA() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let vc = SendViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func goToB() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let vc = ReceivedViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func goToC() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let vc = RegistUUIDViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Helpers
    private func configureActionButton(_ button: UIButton, title: String, subtitle: String, symbol: String, color: UIColor) {
        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()
            cfg.title = title
            cfg.subtitle = subtitle
            cfg.image = UIImage(systemName: symbol)
            cfg.imagePlacement = .leading
            cfg.imagePadding = 8
            cfg.baseBackgroundColor = color
            cfg.baseForegroundColor = .white
            cfg.cornerStyle = .large
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 28)
            cfg.titleAlignment = .leading
            cfg.titleLineBreakMode = .byWordWrapping
            cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            button.configuration = cfg
            button.contentHorizontalAlignment = .leading
        } else {
            // Compose two-line title (title + subtitle) with different fonts
            let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
            let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let composed = NSMutableAttributedString(string: title, attributes: titleAttrs)
            if !subtitle.isEmpty {
                composed.append(NSAttributedString(string: "\n" + subtitle, attributes: subtitleAttrs))
            }
            button.setAttributedTitle(composed, for: .normal)

            // Image + color + shape
            button.setImage(UIImage(systemName: symbol), for: .normal)
            if #available(iOS 13.0, *) {
                button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold), forImageIn: .normal)
            }
            button.tintColor = .white
            button.backgroundColor = color
            button.layer.cornerRadius = 12

            // Layout: paddings and left alignment similar to iOS 15+ branch
            button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 28)
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .left
            button.contentHorizontalAlignment = .leading
            button.semanticContentAttribute = .forceLeftToRight

            // Space between image and text (match imagePadding ≈ 8~12)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            sender.transform = .identity
        }
    }
}


extension String {
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        let localizedValue = self.localized
        return String(format: localizedValue, arguments: arguments)
    }
    
    var localized: String {
        if let bundle = Bundle.localizedBundle {
            return bundle.localizedString(forKey: self, value: self, table: "Localizable")
        } else {
            return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
        }
    }
}

private var localizedBundleKey: UInt8 = 0

extension Bundle {
    static func setLanguageBundle(_ bundle: Bundle) {
        objc_setAssociatedObject(Bundle.main, &localizedBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static var localizedBundle: Bundle? {
        objc_getAssociatedObject(Bundle.main, &localizedBundleKey) as? Bundle
    }
}
