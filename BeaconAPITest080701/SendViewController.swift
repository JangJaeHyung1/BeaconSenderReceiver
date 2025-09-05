//
//  ViewController.swift
//  BeaconAPITest080701
//
//  Created by jh on 2023/08/07.
//



import UIKit
import AVFoundation
import CoreLocation
import CoreBluetooth
// 발신

class SendViewController: UIViewController {
    
    private var beaconTransmitter: BeaconTransmitter?
    
    private let uuidTF: UITextField = {
        let txf = UITextField()
        txf.placeholder = "uuid_placeholder".localized
        txf.layer.borderColor = UIColor.separator.cgColor
        txf.layer.borderWidth = 1
        txf.borderStyle = .none
        txf.backgroundColor = .secondarySystemBackground
        txf.layer.cornerRadius = 10
        txf.font = .systemFont(ofSize: 12)
        txf.clearButtonMode = .whileEditing
//        txf.font = .preferredFont(forTextStyle: .body)
        txf.keyboardType = .asciiCapable
        txf.translatesAutoresizingMaskIntoConstraints = false
        txf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        txf.leftViewMode = .always
        txf.autocapitalizationType = .allCharacters
        txf.autocorrectionType = .no
        txf.smartDashesType = .no
        txf.smartQuotesType = .no
        txf.smartInsertDeleteType = .no
        txf.spellCheckingType = .no
        return txf
    }()
    
    private let majorTF: UITextField = {
        let txf = UITextField()
        txf.placeholder = "major_placeholder".localized
        txf.layer.borderColor = UIColor.separator.cgColor
        txf.layer.borderWidth = 1
        txf.borderStyle = .none
        txf.backgroundColor = .secondarySystemBackground
        txf.layer.cornerRadius = 10
        txf.clearButtonMode = .whileEditing
        txf.font = .preferredFont(forTextStyle: .body)
        txf.keyboardType = .decimalPad
        txf.translatesAutoresizingMaskIntoConstraints = false
        txf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        txf.leftViewMode = .always
        txf.autocapitalizationType = .none
        txf.autocorrectionType = .no
        txf.smartDashesType = .no
        txf.smartQuotesType = .no
        txf.smartInsertDeleteType = .no
        txf.spellCheckingType = .no
        return txf
    }()
    
    private let minorTF: UITextField = {
        let txf = UITextField()
        txf.placeholder = "minor_placeholder".localized
        txf.layer.borderColor = UIColor.separator.cgColor
        txf.layer.borderWidth = 1
        txf.borderStyle = .none
        txf.backgroundColor = .secondarySystemBackground
        txf.layer.cornerRadius = 10
        txf.clearButtonMode = .whileEditing
        txf.font = .preferredFont(forTextStyle: .body)
        txf.keyboardType = .decimalPad
        txf.translatesAutoresizingMaskIntoConstraints = false
        txf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        txf.leftViewMode = .always
        txf.autocapitalizationType = .none
        txf.autocorrectionType = .no
        txf.smartDashesType = .no
        txf.smartQuotesType = .no
        txf.smartInsertDeleteType = .no
        txf.spellCheckingType = .no
        return txf
    }()
    
    private let btn: UIButton = {
        let btn = UIButton()
        btn.setTitle("beacon_send".localized, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let stopBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("beacon_stop".localized, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemOrange
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    private let uuidPickerButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.down.circle"), for: .normal)
        b.tintColor = .quaternaryLabel
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 16)
        b.showsMenuAsPrimaryAction = true
        // menu는 viewDidLoad에서 최초 구성
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(uuidTF)
        view.addSubview(majorTF)
        view.addSubview(minorTF)
        view.addSubview(btn)
        view.addSubview(stopBtn)
        view.backgroundColor = .systemGroupedBackground
        
        // Build form stacks
        let uuidGroup = makeFieldGroup(title: "uuid_label".localized, field: uuidTF)
        let majorGroup = makeFieldGroup(title: "major_label".localized, field: majorTF)
        let minorGroup = makeFieldGroup(title: "minor_label".localized, field: minorTF)

        // Horizontal button row
        let buttonStack = UIStackView(arrangedSubviews: [btn, stopBtn])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill

        // Main vertical content stack
        let contentStack = UIStackView(arrangedSubviews: [uuidGroup, majorGroup, minorGroup, buttonStack])
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadUUIDMenu), name: .uuidListDidChange, object: nil)

        // UUID 필드 오른쪽에 드롭다운(심볼) 버튼 설치
        uuidTF.rightView = uuidPickerButton
        uuidTF.rightViewMode = .always
        reloadUUIDMenu()

        // 앱 저장소에서 첫 UUID 자동 채움 (있다면)
        let registered = UUIDRegistry.load()
        if (uuidTF.text ?? "").isEmpty, let first = registered.first {
            uuidTF.text = first
        }

        // Fixed heights for text fields & buttons
        uuidTF.heightAnchor.constraint(equalToConstant: 44).isActive = true
        majorTF.heightAnchor.constraint(equalToConstant: 44).isActive = true
        minorTF.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stopBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4)
        ])
        
        uuidTF.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        majorTF.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        minorTF.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        stopBtn.addTarget(self, action: #selector(stopButtonTapped(_:)), for: .touchUpInside)

        majorTF.inputAccessoryView = makeNumberToolbar()
        minorTF.inputAccessoryView = makeNumberToolbar()

        // 최초 진입 시 버튼 비활성화
        //btn.isEnabled = false
        //btn.alpha = 0.5
        
        btn.addTarget(self, action: #selector(startButtonTapped(_:)), for: .touchUpInside)
        
        setButton(btn, enabled: false, enabledColor: .systemBlue)
        setButton(stopBtn, enabled: false, enabledColor: .systemOrange)
        
        self.textFieldsDidChange()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        beaconTransmitter?.stopBeaconSend()
        beaconTransmitter = nil
        uuidTF.isEnabled = true
        majorTF.isEnabled = true
        minorTF.isEnabled = true
        btn.setTitle("beacon_send".localized, for: .normal)
        setButton(stopBtn, enabled: false, enabledColor: .systemOrange)
        validateAndUpdateButtons()
    }
    
    @objc func startButtonTapped(_ sender: UIButton) {
        let uuidStr = (uuidTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard UUID(uuidString: uuidStr) != nil else {
            showAlert(title: "input_error".localized, message: "invalid_uuid".localized)
            return
        }
        guard let majorVal = UInt16(majorTF.text ?? ""), let minorVal = UInt16(minorTF.text ?? "") else {
            showAlert(title: "input_error".localized, message: "major_minor_range_error".localized)
            return
        }

        guard let tx = BeaconTransmitter(uuid: uuidStr, major: majorVal, minor: minorVal) else {
            showAlert(title: "error".localized, message: "tx_init_failed".localized)
            return
        }
        beaconTransmitter = tx
        beaconTransmitter?.requestBluetoothPermission()
        beaconTransmitter?.startBeaconSend()

        uuidTF.isEnabled = false
        majorTF.isEnabled = false
        minorTF.isEnabled = false

        btn.setTitle("sending".localized, for: .normal)
        setButton(btn, enabled: false, enabledColor: .systemBlue)
        setButton(stopBtn, enabled: true, enabledColor: .systemOrange)
    }
    
    @objc private func stopButtonTapped(_ sender: UIButton) {
        beaconTransmitter?.stopBeaconSend()
        beaconTransmitter = nil

        uuidTF.isEnabled = true
        majorTF.isEnabled = true
        minorTF.isEnabled = true

        btn.setTitle("beacon_send".localized, for: .normal)
        validateAndUpdateButtons()
        setButton(stopBtn, enabled: false, enabledColor: .systemOrange)
    }

    @objc private func textFieldsDidChange() {
        validateAndUpdateButtons()
    }


    @objc private func reloadUUIDMenu() {
        uuidPickerButton.menu = makeUUIDMenu()
        let hasItems = !UUIDRegistry.load().isEmpty
        uuidPickerButton.isEnabled = hasItems
        uuidPickerButton.tintColor = hasItems ? .tertiaryLabel : .quaternaryLabel
    }

    private func makeUUIDMenu() -> UIMenu {
        let list = UUIDRegistry.load()
        guard !list.isEmpty else {
            let empty = UIAction(title: "uuid_empty".localized, attributes: [.disabled]) { _ in }
            return UIMenu(title: "uuid_select".localized, children: [empty])
        }
        let actions = list.map { u in
            UIAction(title: u) { [weak self] _ in
                self?.uuidTF.text = u
                self?.textFieldsDidChange()
            }
        }
        return UIMenu(title: "uuid_select".localized, children: actions)
    }

    private func validateAndUpdateButtons() {
        let uuidStr = (uuidTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let validUUID = UUID(uuidString: uuidStr) != nil
        let validMajor = UInt16(majorTF.text ?? "") != nil
        let validMinor = UInt16(minorTF.text ?? "") != nil
        let canStart = validUUID && validMajor && validMinor

        let isSending = beaconTransmitter?.startBeaconSendFlag ?? false
        //btn.isEnabled = canStart && !isSending
        //btn.alpha = btn.isEnabled ? 1.0 : 0.5
        setButton(btn, enabled: canStart && !isSending, enabledColor: .systemBlue)
    }

    private func makeNumberToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "done".localized, style: .done, target: self, action: #selector(doneTappedOnNumberPad))
        tb.items = [flex, done]
        return tb
    }

    @objc private func doneTappedOnNumberPad() {
        view.endEditing(true)
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "ok".localized, style: .default))
        present(a, animated: true)
    }
    
    private func makeFieldGroup(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        return stack
    }

    private func setButton(_ button: UIButton, enabled: Bool, enabledColor: UIColor) {
        button.isEnabled = enabled
        button.backgroundColor = enabled ? enabledColor : enabledColor.withAlphaComponent(0.3)
        button.alpha = enabled ? 1.0 : 0.6
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: .uuidListDidChange, object: nil)
    }
}


class BeaconTransmitter: NSObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate {
    
    // MARK: - Properties
    
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var beaconRegion: CLBeaconRegion!
    private var beaconPeripheralData: NSDictionary!
    private var timer: Timer?
    
    private(set) var startBeaconSendFlag = false
    private(set) var beaconSendCount = 1
    
    let uuid: UUID
    let major: CLBeaconMajorValue
    let minor: CLBeaconMinorValue
    
    // MARK: - Initializer
    
    init?(uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMinorValue) {
        guard let parsed = UUID(uuidString: uuid.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        self.uuid = parsed
        self.major = major
        self.minor = minor
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startBeaconSend() {
        guard !startBeaconSendFlag else { return }
        
        beaconRegion = CLBeaconRegion(uuid: self.uuid, major: self.major, minor: self.minor, identifier: self.uuid.uuidString)
        beaconPeripheralData = beaconRegion.peripheralData(withMeasuredPower: -59)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        startBeaconSendFlag = true
        startTimer()
    }
    
    func stopBeaconSend() {
        guard startBeaconSendFlag else { return }
        
        peripheralManager.stopAdvertising()
        startBeaconSendFlag = false
        beaconSendCount = 1
    }
    
    func requestBluetoothPermission() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerCallback), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        if self.timer != nil && self.timer!.isValid {
            self.timer!.invalidate()
            stopBeaconSend()
        }
    }
    
    @objc private func timerCallback() {
        self.beaconSendCount += 1
        if self.beaconSendCount > 2000 {
            stopTimer()
        }
    }
    
    private func intentAppSettings(content: String) {
        guard let topVC = UIApplication.shared.keyWindow?.rootViewController else { return }
        let settingsAlert = UIAlertController(title: "permission_title".localized, message: content, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "ok".localized, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        settingsAlert.addAction(okAction)
        
        let noAction = UIAlertAction(title: "cancel".localized, style: .default)
        settingsAlert.addAction(noAction)
        
        topVC.present(settingsAlert, animated: true, completion: nil)
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            peripheralManager.startAdvertising(beaconPeripheralData as? [String: Any])
        case .poweredOff:
            peripheralManager.stopAdvertising()
        default:
            break
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unauthorized:
            intentAppSettings(content: "allow_bluetooth_permission".localized)
        case .poweredOn:
            startBeaconSend()
        default:
            break
        }
    }
}
