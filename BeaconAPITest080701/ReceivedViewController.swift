//
//  ViewController2.swift
//  BeaconAPITest080701
//
//  Created by jh on 2023/08/09.
//

import UIKit
import CoreLocation
import CoreBluetooth

// 수신
// [CLLocationManagerDelegate 추가 필요]
class ReceivedViewController: UIViewController , CLLocationManagerDelegate, CBCentralManagerDelegate {
    // MARK: - UI (List)
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.keyboardDismissMode = .onDrag
        return tv
    }()

    private let emptyLabel: UILabel = {
        let lb = UILabel()
        lb.text = "no_beacons_detected".localized
        lb.textAlignment = .center
        lb.textColor = .secondaryLabel
        lb.numberOfLines = 0
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isHidden = true
        return lb
    }()

    // MARK: - Data model for the list
    private struct BeaconRow: Hashable {
        let id: String
        let uuid: String
        let major: Int
        let minor: Int
        let rssi: Int
        let proximity: CLProximity
        let updatedAt: Date
    }

    private var beaconMap: [String: BeaconRow] = [:]
    private var beaconItems: [BeaconRow] = []
#if DEBUG
    private var isMockMode = false
#endif
    
    
    
    var bluetoothManager:CBCentralManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BeaconCell.self, forCellReuseIdentifier: BeaconCell.reuseID)
        tableView.separatorStyle = .none
        tableView.rowHeight = 76
        tableView.estimatedRowHeight = 76

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        // [위치 권한 설정 퍼미션 확인 실시]
        bluetoothManager = CBCentralManager()
        bluetoothManager.delegate = self
        self.checkLocationPermission()
        NotificationCenter.default.addObserver(self, selector: #selector(uuidListDidChange(_:)), name: .uuidListDidChange, object: nil)
#if DEBUG
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "demo".localized, style: .plain, target: self, action: #selector(didTapMockData))
#endif
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
            self.loadRegisteredUUIDs()
            self.startBeaconScanning()
        }
        if status == .authorizedWhenInUse {
            // [실시간 비콘 스캔 호출]
            print("authorizedWhenInUse")
            self.loadRegisteredUUIDs()
            self.startBeaconScanning()
        }
        if status == .denied {
            // [권한 설정 창 이동 실시]
            print("denied")
            //            self.startBeaconScanning()
            self.intentAppSettings(content: "allow_location_permission".localized)
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

    // 등록된 UUID 목록을 기반으로 스캔할 대상들
    private var beaconUUIDs: [UUID] = []
    private var beaconRegions: [CLBeaconRegion] = []
    private var beaconConstraints: [CLBeaconIdentityConstraint] = []

    // [특정 uuid , major, minor 일치 값 설정]
    // var beaconRegion: CLBeaconRegion!
    // var beaconRegionConstraints: CLBeaconIdentityConstraint!
    
    // [특정 비콘을 찾은 경우 저장할 변수]
    var searchUUID : String = ""
    var searchMAJOR : Int = 0
    var searchMINOR : Int = 0
    var ibeaconDict : [Int: Int] = [10099: 0, 10001: 0, 30002: 0, 40011: 0]
    func startBeaconScanning() {
        // [비콘 스캔 진행 실시]
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            if CLLocationManager.isRangingAvailable() { // 비콘 스캔 기능을 이용할 수 있는 경우
                if self.startBeaconScanFlag == false {
                    // 등록된 UUID 불러오기 (없으면 안내)
                    if self.beaconUUIDs.isEmpty {
                        self.showAlert(
                            tittle: "notice".localized,
                            content: String(format: "register_uuid_first_format".localized, UUIDRegistry.limit),
                            okBtb: "ok".localized,
                            noBtn: ""
                        )
                        return
                    }

                    // 최대 20개 region 모니터링 가능 (iOS 한도)
                    self.beaconRegions.removeAll()
                    self.beaconConstraints.removeAll()

                    for uuid in self.beaconUUIDs {
                        let region = CLBeaconRegion(uuid: uuid, identifier: uuid.uuidString)
                        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
                        self.beaconRegions.append(region)
                        self.beaconConstraints.append(constraint)

                        self.locationManager.startMonitoring(for: region)
                        self.locationManager.startRangingBeacons(satisfying: constraint)
                    }

                    self.startBeaconScanFlag = true
                }
            } else {
                self.showAlert(
                    tittle: "notice".localized,
                    content: "beacon_scan_required".localized,
                    okBtb: "ok".localized,
                    noBtn: ""
                )
            }
        } else {
            self.showAlert(
                tittle: "notice".localized,
                content: "beacon_scan_required".localized,
                okBtb: "ok".localized,
                noBtn: ""
            )
        }
    }
    //    private func calculateDistance(rssi: Int, txPower: Int, pathLossExponent: Double = 2.0){
    //        10.0.pow((rssi - txPower) / (-10 * Int(pathLossExponent)))
    //    }
    
    // [실시간 비콘 감지 수행 부분]
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // 비콘이 하나도 안 잡히는 경우
        guard !beacons.isEmpty else {
            beaconMap.removeAll()
            beaconItems.removeAll()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateEmptyState(with: "no_beacons_detected".localized)
            }
            return
        }

        let now = Date()
        var newMap: [String: BeaconRow] = [:]
        for b in beacons where b.rssi != 0 {
            let key = "\(b.uuid.uuidString)-\(b.major)-\(b.minor)"
            let row = BeaconRow(
                id: key,
                uuid: b.uuid.uuidString,
                major: b.major.intValue,
                minor: b.minor.intValue,
                rssi: b.rssi,
                proximity: b.proximity,
                updatedAt: now
            )
            newMap[key] = row
        }
        beaconMap = newMap

        // 정렬: 근접도(즉시/가까움/멀리/미지) → RSSI 내림차순
        func rank(_ p: CLProximity) -> Int { switch p { case .immediate: return 0; case .near: return 1; case .far: return 2; case .unknown: return 3 } }
        beaconItems = Array(beaconMap.values).sorted { a, b in
            if rank(a.proximity) != rank(b.proximity) { return rank(a.proximity) < rank(b.proximity) }
            return a.rssi > b.rssi
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState(with: nil)
        }
    }
    
    
    
    // [실시간 비콘 스캐닝 종료]
    func stopBeaconScanning(){
        if self.startBeaconScanFlag == true {
            for region in self.beaconRegions {
                self.locationManager.stopMonitoring(for: region)
            }
            for constraint in self.beaconConstraints {
                self.locationManager.stopRangingBeacons(satisfying: constraint)
            }
            self.startBeaconScanFlag = false // 비콘 스캔 시작 플래그 초기화
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
        }
    }
    
    
    // 등록된 UUID를 UserDefaults에서 읽어옵니다.
    private func loadRegisteredUUIDs() {
        let strings = UUIDRegistry.load()
        self.beaconUUIDs = strings.compactMap { UUID(uuidString: $0) }
    }

    // UUID 목록이 변경되면 스캔을 재시작합니다.
    @objc private func uuidListDidChange(_ note: Notification) {
        print("UUID list changed. Restarting beacon scan.")
        if self.startBeaconScanFlag { self.stopBeaconScanning() }
        self.loadRegisteredUUIDs()
        self.startBeaconScanning()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // [애플리케이션 설정창 이동 실시 메소드]
    func intentAppSettings(content:String){
        // 앱 설정창 이동 실시
        let settingsAlert = UIAlertController(title: "permission_title".localized, message: content, preferredStyle: UIAlertController.Style.alert)
        
        let okAction = UIAlertAction(title: "ok".localized, style: .default) { (action) in
            // [확인 버튼 클릭 이벤트 내용 정의 실시]
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        settingsAlert.addAction(okAction) // 버튼 클릭 이벤트 객체 연결
        
        let noAction = UIAlertAction(title: "cancel".localized, style: .default) { (action) in
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
    
    private func updateEmptyState(with message: String?) {
        let isEmpty = beaconItems.isEmpty
        emptyLabel.text = message ?? "no_nearby_beacons".localized
        emptyLabel.isHidden = !isEmpty
        tableView.isScrollEnabled = !isEmpty
    }

#if DEBUG
    @objc private func didTapMockData() {
        isMockMode.toggle()
        if isMockMode {
            // 데모 모드 시작: 실제 스캔 중지 후 더미 데이터 표시
            if startBeaconScanFlag { stopBeaconScanning() }
            loadMockBeacons()
            navigationItem.rightBarButtonItem?.title = "live".localized
        } else {
            // 실시간 모드 복귀
            beaconMap.removeAll()
            beaconItems.removeAll()
            tableView.reloadData()
            updateEmptyState(with: nil)
            self.loadRegisteredUUIDs()
            self.startBeaconScanning()
            navigationItem.rightBarButtonItem?.title = "demo".localized
        }
    }

    private func loadMockBeacons() {
        let now = Date()
        let samples: [BeaconRow] = [
            BeaconRow(id: "F7A3E806-AAAA-AAAA-AAAA-0783669EBEB1-100-1", uuid: "F7A3E806-F5BB-43F8-BA87-0783669EBEB1", major: 100, minor: 1, rssi: -42, proximity: .immediate, updatedAt: now),
            BeaconRow(id: "F7A3E806-BBBB-BBBB-BBBB-0783669EBEB1-200-3", uuid: "74278BDA-B644-4520-8F0C-720EAF059935", major: 200, minor: 3, rssi: -58, proximity: .near, updatedAt: now),
            BeaconRow(id: "F7A3E806-CCCC-CCCC-CCCC-0783669EBEB1-50-9", uuid: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0", major: 50, minor: 9, rssi: -75, proximity: .far, updatedAt: now),
            BeaconRow(id: "F7A3E806-DDDD-DDDD-DDDD-0783669EBEB1-10-2", uuid: "00112233-4455-6677-8899-AABBCCDDEEFF", major: 10, minor: 2, rssi: -90, proximity: .unknown, updatedAt: now)
        ]
        beaconItems = samples
        beaconMap = Dictionary(uniqueKeysWithValues: samples.map { ($0.id, $0) })
        tableView.reloadData()
        updateEmptyState(with: nil)
    }
#endif

    private func proximityString(_ p: CLProximity) -> String {
        switch p {
        case .immediate: return "immediate"
        case .near: return "near"
        case .far: return "far"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
    
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
}

// MARK: - Custom Cell
final class BeaconCell: UITableViewCell {
    static let reuseID = "BeaconCell"

    private let container: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        lb.textColor = .label
        lb.numberOfLines = 1
        return lb
    }()

    private let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.font = .preferredFont(forTextStyle: .footnote)
        lb.textColor = .secondaryLabel
        lb.numberOfLines = 1
        return lb
    }()

    private let rssiLabel: InsetLabel = {
        let lb = InsetLabel()
        lb.numberOfLines = 0
        lb.textAlignment = .right
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        lb.textColor = .secondaryLabel
        lb.insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        lb.backgroundColor = .clear
        lb.setContentHuggingPriority(.required, for: .horizontal)
        return lb
    }()

    private let stack: UIStackView = {
        let st = UIStackView()
        st.translatesAutoresizingMaskIntoConstraints = false
        st.axis = .vertical
        st.spacing = 4
        st.alignment = .fill
        st.backgroundColor = .clear
        return st
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(container)
        container.addSubview(stack)
        container.addSubview(rssiLabel)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: rssiLabel.leadingAnchor, constant: -12),

            rssiLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            rssiLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(uuid: String, major: Int, minor: Int, rssi: Int, proximity: CLProximity) {
        titleLabel.text = "\(major)  /  \(minor)"
        subtitleLabel.text = "\(uuid)"
        rssiLabel.text = String(format: "rssi_and_proximity_multiline".localized, rssi, proximityString(proximity))
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


    // Small padding label for RSSI capsule
    private class InsetLabel: UILabel {
        var insets: UIEdgeInsets = .zero
        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: insets))
        }
        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + insets.left + insets.right,
                          height: size.height + insets.top + insets.bottom)
        }
    }
}



extension ReceivedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beaconItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = beaconItems[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BeaconCell.reuseID, for: indexPath) as? BeaconCell else {
            return UITableViewCell()
        }
        cell.configure(uuid: row.uuid, major: row.major, minor: row.minor, rssi: row.rssi, proximity: row.proximity)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = beaconItems[indexPath.row]
        let detail = BeaconDetailViewController(
            uuid: row.uuid,
            major: row.major,
            minor: row.minor,
            rssi: row.rssi,
            proximity: row.proximity
        )
        if let sheet = detail.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        present(detail, animated: true)
    }
}
