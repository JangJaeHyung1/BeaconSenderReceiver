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

class ViewController2: UIViewController {
    
    private var beaconTransmitter: BeaconTransmitter?
    
    private let major: UITextField = {
        let txf = UITextField()
        txf.placeholder = "major"
        txf.borderStyle = .line
        txf.backgroundColor = .white
        txf.textColor = .black
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
        btn.setTitle("start", for: .normal)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconTransmitter = BeaconTransmitter(uuid: "F7A3E806-F5BB-43F8-BA87-0783669EBEB1", major: 10164, minor: 1001)
        beaconTransmitter?.requestBluetoothPermission()
        beaconTransmitter?.startBeaconSend()
    }
    
    
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        beaconTransmitter?.startBeaconSend()
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        beaconTransmitter?.stopBeaconSend()
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
    
    init(uuid: String, major: CLBeaconMajorValue, minor: CLBeaconMinorValue) {
        self.uuid = UUID(uuidString: uuid)!
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
        let settingsAlert = UIAlertController(title: "권한 설정 알림", message: content, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        settingsAlert.addAction(okAction)
        
        let noAction = UIAlertAction(title: "취소", style: .default)
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
            intentAppSettings(content: "블루투스 사용 권한을 허용해주세요")
        case .poweredOn:
            startBeaconSend()
        default:
            break
        }
    }
}
