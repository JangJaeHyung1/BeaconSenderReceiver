# BeaconSenderReceiver


비콘 신호를 발신하고 수신하는 간단한 iOS 프로젝트입니다.

## 앱 미리보기


<!-- 실제 스크린샷 이미지 4장 -->
<p float="left">
  <img src="https://github.com/user-attachments/assets/1456c05e-308c-4fcb-bb93-67f18604c6f4" width="300" />
  <img src="https://github.com/user-attachments/assets/c95e3c32-7427-4e44-a4a4-93b2a65d2d25" width="300" />
  <img src="https://github.com/user-attachments/assets/6181c984-7b45-4628-b64e-0f88167d0897" width="300" />
  <img src="https://github.com/user-attachments/assets/4ea8a160-201c-4a43-ad4e-1a36b238f279" width="300" />
</p>

## 주요 기능

- iBeacon 신호 발신 (uuid, Major, minor 설정)
- 비콘 수신 및 거리 추정 (immediate, near, far)
- 실시간 UI 업데이트로 비콘 거리 시각화

  
## 주석

> 수신기는 등록된 uuid에 해당하는 비콘 신호만 수신 가능 (beacon uuid 최대 20개 등록 가능).
> 출처: [Getting Started with iBeacon - Apple](https://developer.apple.com/ibeacon/Getting-Started-with-iBeacon.pdf)
