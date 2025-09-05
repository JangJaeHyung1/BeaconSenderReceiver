//
//  RegistUUIDViewController.swift
//  BeaconAPITest080701
//
//  Created by jh on 9/4/25.
//

import UIKit

// 프로젝트 전역에서 사용할 알림 이름
extension Notification.Name {
    static let uuidListDidChange = Notification.Name("UUIDListDidChange")
}

// 간단한 영구 저장소
struct UUIDRegistry {
    static let key = "RegisteredUUIDs"
    static let limit = 20 // iOS에서 region monitoring 최대 20개 (UUID 기준으로 설계)

    // 파일 기반 내장 스토리지 (Application Support/uuids.json)
    private static var storeURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("uuids.json")
    }

    static func load() -> [String] {
        // 1) 파일에서 우선 로드
        do {
            let url = storeURL
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let arr = try JSONDecoder().decode([String].self, from: data)
                // 백워드 호환: UserDefaults에도 반영
                UserDefaults.standard.set(arr, forKey: key)
                return arr
            }
        } catch {
            print("UUIDRegistry load file error:", error)
        }
        // 2) 파일이 없다면 UserDefaults에서 로드
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func save(_ strings: [String]) {
        // UserDefaults 저장
        UserDefaults.standard.set(strings, forKey: key)
        // 파일 저장
        do {
            let url = storeURL
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(strings)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("UUIDRegistry save file error:", error)
        }
        NotificationCenter.default.post(name: .uuidListDidChange, object: nil)
    }
}

final class RegistUUIDViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var uuidStrings: [String] = UUIDRegistry.load()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "uuid_register".localized
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            editButtonItem
        ]

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    @objc private func addTapped() {
        presentEditor(title: "uuid_add".localized, initial: nil) { [weak self] newValue in
            guard let self else { return }
            if self.uuidStrings.count >= UUIDRegistry.limit {
                self.simpleAlert(String(format: "uuid_max_format".localized, UUIDRegistry.limit))
                return
            }
            guard self.isValidUUIDString(newValue) else {
                self.simpleAlert("invalid_uuid".localized)
                return
            }
            if self.uuidStrings.contains(where: { $0.caseInsensitiveCompare(newValue) == .orderedSame }) {
                self.simpleAlert("uuid_already_registered".localized)
                return
            }
            self.uuidStrings.append(newValue.uppercased())
            UUIDRegistry.save(self.uuidStrings)
            self.tableView.reloadData()
        }
    }

    private func presentEditor(title: String, initial: String?, onSave: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: "enter_uuid".localized, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "uuid_placeholder".localized
            tf.autocapitalizationType = .allCharacters
            tf.text = initial
        }
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "save".localized, style: .default, handler: { _ in
            let value = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            onSave(value)
        }))
        present(alert, animated: true)
    }

    private func isValidUUIDString(_ s: String) -> Bool {
        return UUID(uuidString: s) != nil
    }

    private func simpleAlert(_ message: String) {
        let a = UIAlertController(title: "notice".localized, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "ok".localized, style: .default))
        present(a, animated: true)
    }
}

extension RegistUUIDViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        uuidStrings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = uuidStrings[indexPath.row]
        cell.contentConfiguration = config
        return cell
    }

    // 편집(삭제)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            uuidStrings.remove(at: indexPath.row)
            UUIDRegistry.save(uuidStrings)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // 스와이프 액션: 편집
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "edit".localized) { [weak self] _, _, done in
            guard let self else { return }
            let current = self.uuidStrings[indexPath.row]
            self.presentEditor(title: "uuid_edit".localized, initial: current) { newValue in
                guard self.isValidUUIDString(newValue) else {
                    self.simpleAlert("invalid_uuid".localized)
                    return
                }
                // 중복 체크 (자기 자신 제외)
                if self.uuidStrings.enumerated().contains(where: { idx, s in
                    idx != indexPath.row && s.caseInsensitiveCompare(newValue) == .orderedSame
                }) {
                    self.simpleAlert("uuid_already_registered".localized)
                    return
                }
                self.uuidStrings[indexPath.row] = newValue.uppercased()
                UUIDRegistry.save(self.uuidStrings)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            done(true)
        }
        let delete = UIContextualAction(style: .destructive, title: "delete".localized) { [weak self] _, _, done in
            guard let self else { return }
            self.uuidStrings.remove(at: indexPath.row)
            UUIDRegistry.save(self.uuidStrings)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = uuidStrings[indexPath.row]
        UIPasteboard.general.string = value
        tableView.deselectRow(at: indexPath, animated: true)

        // 짧게 표시되는 알림
        let alert = UIAlertController(title: nil, message: "copied".localized, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true)
        }
    }
}
