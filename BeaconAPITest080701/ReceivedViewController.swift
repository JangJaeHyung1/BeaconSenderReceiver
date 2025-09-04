//
//  ViewController2.swift
//  BeaconAPITest080701
//
//  Created by jh on 2023/08/09.
//

import UIKit
import AVFoundation
import Photos
import CoreLocation
import CoreBluetooth

// 수신
// [CLLocationManagerDelegate 추가 필요]
class ReceivedViewController: UIViewController , CLLocationManagerDelegate, CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is On.")
            break
        case .poweredOff:
            print("Bluetooth is Off.")
            break
        case .resetting:
            print("Bluetooth is resetting.")
            break
        case .unauthorized:
            print("Bluetooth is unauthorized.")
            break
        case .unsupported:
            print("Bluetooth is unsupported.")
            break
        case .unknown:
            print("Bluetooth is unknown.")
            break
        default:
            break
        }
    }
    
    private let text: UITextView = {
        let lbl = UITextView()
        lbl.font = .systemFont(ofSize: 13)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .label
        lbl.backgroundColor = .systemBackground
        lbl.text = ""
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    
    
    var bluetoothManager:CBCentralManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(text)
        text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        text.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        text.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        // [위치 권한 설정 퍼미션 확인 실시]
        bluetoothManager = CBCentralManager()
        bluetoothManager.delegate = self
        self.checkLocationPermission()
    }
    
    
    /*
     [위치 권한 요청]
     필요 : import CoreLocation
     */
    var locationManager : CLLocationManager!
    func checkLocationPermission(){
        
        self.locationManager = CLLocationManager.init() // locationManager 초기화
        self.locationManager.delegate = self // 델리게이트 넣어줌
        print("권한 체크1")
        self.locationManager.requestAlwaysAuthorization() // 위치 권한 설정 값을 받아옵니다
        print("권한 체크2")
        self.locationManager.startUpdatingLocation() // 위치 업데이트 시작
        self.locationManager.allowsBackgroundLocationUpdates = true // 백그라운드에서도 위치를 체크할 것인지에 대한 여부
        self.locationManager.pausesLocationUpdatesAutomatically = false // false 설정해야 백그라운드에서 멈추지 않고 돈다
    }
    
    
    // [위치 서비스에 대한 권한 확인 실시]
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            // [실시간 비콘 스캔 호출]
            print("authorizedAlways")
            let time = Timestamp()
            time.printTimestamp()
            self.startBeaconScanning()
        }
        if status == .authorizedWhenInUse {
            // [실시간 비콘 스캔 호출]
            print("authorizedWhenInUse")
            let time = Timestamp()
            time.printTimestamp()
            self.startBeaconScanning()
        }
        if status == .denied {
            // [권한 설정 창 이동 실시]
            print("denied")
            //            self.startBeaconScanning()
            self.intentAppSettings(content: "위치사용 권한을 허용해주세요")
            self.locationManager.requestAlwaysAuthorization()
        }
        if status == .restricted || status == .notDetermined {
            // [권한 설정 창 이동 실시]
            print("restricted")
            //            self.startBeaconScanning()
            //            self.intentAppSettings(content: "위치사용 권한을 허용해주세요")
        }
    }
    
    
    // [실시간 비콘 스캐닝 진행]
    var startBeaconScanFlag = false // 비콘 스캔 진행 플래그 값
    var beaconScanCount: Float = 0 // 비콘 스캔 진행 카운트 값
    var beaconScanCheck = false // 일치하는 비콘을 찾은 경우 플래그 값
    
    // [비콘 설정 셋팅 : 설정한 uuid , major , minor 값을 가지고 실시간 비콘 스캔 진행]
    let uuid = UUID(uuidString: "F7A3E806-F5BB-43F8-BA87-0783669EBEB1")!
    //let major = 123 // 필요시 사용
    //let minor = 456 // 필요시 사용
    
    // [특정 uuid , major, minor 일치 값 설정]
    var beaconRegion: CLBeaconRegion!
    var beaconRegionConstraints: CLBeaconIdentityConstraint!
    
    // [특정 비콘을 찾은 경우 저장할 변수]
    var searchUUID : String = ""
    var searchMAJOR : Int = 0
    var searchMINOR : Int = 0
    var ibeaconDict : [Int: Int] = [10099: 0, 10001: 0, 30002: 0, 40011: 0]
    func startBeaconScanning() {
        // [비콘 스캔 진행 실시]
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            if CLLocationManager.isRangingAvailable() { // 비콘 스캔 기능을 이용할 수 있는 경우
                
                // [비콘 스캔이 진행 되지 않은 경우 확인]
                if self.startBeaconScanFlag == false {
                    
                    // [필요시 사용 [1 셋팅] : 특정 uuid , major, minor 일치 값 설정]
                    //self.beaconRegion = CLBeaconRegion.init(uuid: self.uuid, major: CLBeaconMajorValue(self.major), minor: CLBeaconMinorValue(self.minor), identifier: self.uuid.uuidString)
                    //self.beaconRegionConstraints = CLBeaconIdentityConstraint(uuid: self.uuid, major: CLBeaconMajorValue(self.major), minor: CLBeaconMinorValue(self.minor))
                    
                    
                    
                    // [필요시 사용 [2 셋팅] : 특정 uuid 일치 값 설정]
                    self.beaconRegion = CLBeaconRegion.init(uuid: self.uuid, identifier: self.uuid.uuidString)
                    self.beaconRegionConstraints = CLBeaconIdentityConstraint(uuid: self.uuid)
                    
                    
                    // [비콘 스캔 시작]
                    self.locationManager.startMonitoring(for: self.beaconRegion)
                    self.locationManager.startRangingBeacons(satisfying: self.beaconRegionConstraints)
                    
                    
                    // [비콘 스캔 시작 플래그 값 지정]
                    self.startBeaconScanFlag = true
                    self.startTimer() // 타이머 시작 호출
                }
            }
            else {
                // [권한 설정 창 이동 실시]
                self.showAlert(tittle: "알림", content: "비콘스캔 기능 확인이 필요합니다", okBtb: "확인", noBtn: "")
            }
        }
        else {
            // [권한 설정 창 이동 실시]
            self.showAlert(tittle: "알림", content: "비콘스캔 기능 확인이 필요합니다", okBtb: "확인", noBtn: "")
        }
    }
    //    private func calculateDistance(rssi: Int, txPower: Int, pathLossExponent: Double = 2.0){
    //        10.0.pow((rssi - txPower) / (-10 * Int(pathLossExponent)))
    //    }
    
    // [실시간 비콘 감지 수행 부분]
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        var textTemp = ""
        
        if beacons.count > 0 { // [스캔된 비콘 개수가 있는 경우]
            for (idx, beacon) in beacons.enumerated() {
                
                var proximity = ""
                switch beacon.proximity {
                case .far:
                    proximity = "far"
                case .immediate:
                    proximity = "immediate"
                case .near:
                    proximity = "near"
                case .unknown:
                    proximity = "unknown"
                @unknown default:
                    proximity = "unknown"
                }
                
                if beacon.rssi != 0 {
                    textTemp += "\n\nbeacon\(idx)\nbeacon uuid : \(beacon.uuid)\nbeacon major : \(beacon.major)\nbeacon minor : \(beacon.minor)\nbeacon rssi : \(beacon.rssi)\nbeacon proximity : \(proximity)"
                }
                
            }
            DispatchQueue.main.async {
                self.text.text = textTemp
            }
            for beacon in beacons {
                print("beacon: \(beacon.major)")
            }
            print("")
        }
        else {
            print("감지 끊김")
            self.text.text = "감지 끊김"
            for beacon in beacons {
                DispatchQueue.main.async {
                    self.text.text = "감지 끊김\n\nbeacon uuid : \(beacon.uuid)\nbeacon major : \(beacon.major)\nbeacon minor : \(beacon.minor)\nbeacon rssi : \(beacon.rssi)"
                }
                print("beacon uuid : ", beacon.uuid)
                print("beacon major : ", beacon.major)
                print("beacon minor : ", beacon.minor)
            }
            
        }
        
        
    }
    
    
    
    // [실시간 비콘 스캐닝 종료]
    func stopBeaconScanning(){
        // [실시간 비콘 스캔을 진행한 경우]
        if self.startBeaconScanFlag == true {
            self.locationManager.stopMonitoring(for: self.beaconRegion)
            self.locationManager.stopRangingBeacons(satisfying: self.beaconRegionConstraints)
            self.startBeaconScanFlag = false // 비콘 스캔 시작 플래그 초기화
            self.beaconScanCount = 1 // 비콘 스캔 카운트 초기화
            if self.beaconScanCheck == true { // 카운트 동안에 비콘 스캔 일치값 찾음
                self.beaconScanCheck = false // 비콘 일치값 찾음 플래그 초기화
                
                print("uuid : ", self.searchUUID)
                print("major : ", self.searchMAJOR)
                print("minor : ", self.searchMINOR)
                
                // 저장 값 초기화 실시
                self.searchUUID = ""
                self.searchMAJOR = 0
                self.searchMINOR = 0
            }
            else { // 카운트 동안에 비콘 스캔 일치값 찾지 못함
                self.beaconScanCheck = false // 비콘 일치값 찾음 플래그 초기화
            }
        }
    }
    
    
    // [실시간 반복 작업 시작 호출]
    var timer : Timer?
    func startTimer(){
        // [타이머 객체 생성 실시]
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerCallback), userInfo: nil, repeats: true)
    }
    // [실시간 반복 작업 수행 부분]
    @objc func timerCallback() {
        
        // [처리할 로직 작성 실시]
        self.beaconScanCount += 1 // 1씩 카운트 값 증가 실시
        if self.beaconScanCount > 2000 { // 카운트 값이 10인 경우
            //            self.stopTimer() // 타이머 종료 실시
        }
    }
    // [실시간 반복 작업 정지 호출]
    func stopTimer(){
        // [실시간 반복 작업 중지]
        if self.timer != nil && self.timer!.isValid {
            self.timer!.invalidate()
            self.stopBeaconScanning() // 비콘 스캔 종료 호출
        }
    }
    
    
    
    
    // [애플리케이션 설정창 이동 실시 메소드]
    func intentAppSettings(content:String){
        // 앱 설정창 이동 실시
        let settingsAlert = UIAlertController(title: "권한 설정 알림", message: content, preferredStyle: UIAlertController.Style.alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
            // [확인 버튼 클릭 이벤트 내용 정의 실시]
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        settingsAlert.addAction(okAction) // 버튼 클릭 이벤트 객체 연결
        
        let noAction = UIAlertAction(title: "취소", style: .default) { (action) in
            // [취소 버튼 클릭 이벤트 내용 정의 실시]
            return
        }
        settingsAlert.addAction(noAction) // 버튼 클릭 이벤트 객체 연결
        
        // [alert 팝업창 활성 실시]
        present(settingsAlert, animated: false, completion: nil)
    }
    
    
    // [alert 팝업창 호출 메소드 정의 실시 : 이벤트 호출 시]
    // 호출 방법 : showAlert(tittle: "title", content: "content", okBtb: "확인", noBtn: "취소")
    func showAlert(tittle:String, content:String, okBtb:String, noBtn:String) {
        // [UIAlertController 객체 정의 실시]
        let alert = UIAlertController(title: tittle, message: content, preferredStyle: UIAlertController.Style.alert)
        
        // [인풋으로 들어온 확인 버튼이 nil 아닌 경우]
        if(okBtb != "" && okBtb.count>0){
            let okAction = UIAlertAction(title: okBtb, style: .default) { (action) in
                // [확인 버튼 클릭 이벤트 내용 정의 실시]
                return
            }
            alert.addAction(okAction) // 버튼 클릭 이벤트 객체 연결
        }
        
        // [인풋으로 들어온 취소 버튼이 nil 아닌 경우]
        if(noBtn != "" && noBtn.count>0){
            let noAction = UIAlertAction(title: noBtn, style: .default) { (action) in
                // [취소 버튼 클릭 이벤트 내용 정의 실시]
                return
            }
            alert.addAction(noAction) // 버튼 클릭 이벤트 객체 연결
        }
        
        // [alert 팝업창 활성 실시]
        present(alert, animated: false, completion: nil)
    }
    
}

class Timestamp {
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()
    
    func printTimestamp() {
        print(dateFormatter.string(from: Date()))
    }
}
