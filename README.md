# BeaconSenderReceiver


비콘 신호를 발신하고 수신하는 iOS 프로젝트입니다.

## 앱 미리보기


<!-- 실제 스크린샷 이미지 7장 -->
<p>
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/52d6d556-cb91-4bd2-8bc3-e232bd08c943" />
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/73fb4991-19c5-462f-954e-1a899f40a72e" />
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/37adc301-d9a3-4a89-9680-ad8121a7dd69" />
  <br/>
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/589cb1ad-eb21-426f-b7ea-84d171e0a7ef" />
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/909a7f48-7fee-4d10-9c1c-b8f92e80e1db" />
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/4eb671ba-a4d4-4603-a207-bdfe2e48c9a7" />
  <br/>
  <img width="280" alt="Image" src="https://github.com/user-attachments/assets/bc6c3abe-11c7-464f-8319-4ef48f21a0a6" />
</p>

## 주요 기능

- iBeacon 신호 발신 (uuid, Major, minor 설정)
- 비콘 수신 및 거리 추정 (immediate, near, far)
- 실시간 UI 업데이트로 비콘 거리 시각화

  
## 주석

> 수신기는 등록된 uuid에 해당하는 비콘 신호만 수신 가능 (beacon uuid 최대 20개 등록 가능)

> 출처: [Getting Started with iBeacon - Apple](https://developer.apple.com/ibeacon/Getting-Started-with-iBeacon.pdf)
