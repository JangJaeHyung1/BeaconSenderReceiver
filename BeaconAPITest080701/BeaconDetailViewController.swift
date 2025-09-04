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
        lb.text = "Beacon 상세 정보"
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
        cfg.title = "UUID 복사"
        cfg.image = UIImage(systemName: "doc.on.doc")
        cfg.imagePadding = 6
        cfg.cornerStyle = .medium
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let copyAllButton: UIButton = {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "전체 복사"
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

        let uuidRow = makeRow(title: "UUID", value: uuid)
        let majorRow = makeRow(title: "Major", value: "\(major)")
        let minorRow = makeRow(title: "Minor", value: "\(minor)")
        let rssiRow = makeRow(title: "RSSI", value: "\(rssi) dBm")
        let proxRow = makeRow(title: "Proximity", value: proximityString(proximity))

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
        showToast("복사되었습니다")
    }

    @objc private func copyAll() {
        let text = "uuid: \(uuid)\nmajor: \(major)\nminor: \(minor)\nrssi: \(rssi)\nproximity: \(proximityString(proximity))"
        UIPasteboard.general.string = text
        showToast("복사되었습니다")
    }

    private func proximityString(_ p: CLProximity) -> String {
        switch p {
        case .immediate: return "immediate"
        case .near: return "near"
        case .far: return "far"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
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

