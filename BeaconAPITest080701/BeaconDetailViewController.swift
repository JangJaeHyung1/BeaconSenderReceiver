//
//  BeaconDetailViewController.swift
//  BeaconAPITest080701
//
//  Created by jh on 9/5/25.
//

import UIKit
import CoreLocation
import CoreBluetooth

class BeaconDetailViewController: UIViewController {
    private let uuid: String
    private let major: Int
    private let minor: Int
    private let rssi: Int
    private let proximity: CLProximity

    init(uuid: String, major: Int, minor: Int, rssi: Int, proximity: CLProximity) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.rssi = rssi
        self.proximity = proximity
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "detail_title".localized
        lb.font = .preferredFont(forTextStyle: .headline)
        lb.textColor = .label
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()

    private func makeRow(title: String, value: String) -> UIStackView {
        let tl = UILabel()
        tl.text = title
        tl.font = .preferredFont(forTextStyle: .subheadline)
        tl.textColor = .secondaryLabel
        tl.setContentHuggingPriority(.required, for: .horizontal)

        let vl = UILabel()
        vl.text = value
        vl.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        vl.textColor = .label
        vl.numberOfLines = 0

        let st = UIStackView(arrangedSubviews: [tl, vl])
        st.axis = .horizontal
        st.spacing = 12
        st.alignment = .top
        return st
    }

    private let copyUUIDButton: UIButton = {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "copy_uuid".localized
        cfg.image = UIImage(systemName: "doc.on.doc")
        cfg.imagePadding = 6
        cfg.cornerStyle = .medium
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let copyAllButton: UIButton = {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "copy_all".localized
        cfg.image = UIImage(systemName: "square.and.arrow.up")
        cfg.imagePadding = 6
        cfg.cornerStyle = .medium
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let uuidRow = makeRow(title: "uuid_label".localized, value: uuid)
        let majorRow = makeRow(title: "major_label".localized, value: "\(major)")
        let minorRow = makeRow(title: "minor_label".localized, value: "\(minor)")
        let rssiRow = makeRow(title: "rssi_label".localized, value: String(format: "rssi_value_format".localized, rssi))
        let proxRow = makeRow(title: "proximity_label".localized, value: proximityString(proximity))

        let content = UIStackView(arrangedSubviews: [titleLabel, uuidRow, majorRow, minorRow, rssiRow, proxRow])
        content.axis = .vertical
        content.spacing = 14
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            content.setCustomSpacing(24, after: titleLabel) // title 아래 간격만 크게
        }

        let buttonRow = UIStackView(arrangedSubviews: [copyUUIDButton, copyAllButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(content)
        view.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),

            buttonRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonRow.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            copyUUIDButton.heightAnchor.constraint(equalToConstant: 44),
            copyAllButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        copyUUIDButton.addTarget(self, action: #selector(copyUUID), for: .touchUpInside)
        copyAllButton.addTarget(self, action: #selector(copyAll), for: .touchUpInside)
    }

    @objc private func copyUUID() {
        UIPasteboard.general.string = uuid
        showToast("copied".localized)
    }

    @objc private func copyAll() {
        let text = "uuid: \(uuid)\nmajor: \(major)\nminor: \(minor)\nrssi: \(rssi)\nproximity: \(proximityString(proximity))"
        UIPasteboard.general.string = text
        showToast("copied".localized)
    }

    private func proximityString(_ p: CLProximity) -> String {
        switch p {
        case .immediate: return "proximity_immediate".localized
        case .near: return "proximity_near".localized
        case .far: return "proximity_far".localized
        case .unknown: return "proximity_unknown".localized
        @unknown default: return "proximity_unknown".localized
        }
    }

    private func showToast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
}

