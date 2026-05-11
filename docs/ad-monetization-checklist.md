# 광고 수익화 운영 체크리스트

이 문서는 바위게캘린더 광고 수익화 기능을 배포하기 전에 콘솔에서 확인해야 할 일을 정리합니다.

## 현재 코드 반영 상태

- AdMob SDK 추가 완료
- AdMob App ID 설정 완료
- 하단 배너 광고 연결 완료
- 개인 콘텐츠 생성 횟수 기반 전면 광고 연결 완료
- 광고 제거 인앱결제 코드 연결 완료
- 설정 화면에 광고 제거 구매/복원 UI 추가 완료
- Debug 빌드에서는 Google 테스트 광고 ID 사용
- Debug 빌드에서는 Xcode StoreKit Configuration으로 광고 제거 결제 시트를 테스트
- Debug 빌드에서는 광고 제거 로컬 적용/해제 보조 버튼 제공
- Release 빌드에서는 운영 광고 ID 사용
- Release 빌드에서는 App Store 실제 인앱결제 사용

## 코드에 설정된 값

| 항목 | 값 |
|---|---|
| AdMob App ID | `ca-app-pub-4795000952052288~4177969641` |
| Banner Ad Unit ID | `ca-app-pub-4795000952052288/1876074083` |
| Interstitial Ad Unit ID | `ca-app-pub-4795000952052288/5463965306` |
| Remove Ads Product ID | `rockcrabcalendar.remove_ads` |
| Remove Ads Price | `3,900원` |
| Interstitial Trigger | 개인 콘텐츠 신규 생성 5회마다 |

## 전면 광고 노출 정책

전면 광고 카운트는 사용자가 앱에 개인 콘텐츠를 새로 생성한 경우에만 증가합니다.

카운트 포함:

- 개인 일정 신규 추가
- 일정 기록 신규 추가

카운트 제외:

- 개인 일정 수정
- QWER 일정 신규 추가/수정
- 일정 기록 수정
- 삭제

광고 제거 구매가 적용된 사용자는 카운트가 누적되어도 전면 광고를 표시하지 않습니다.

구현 기준 파일:

- `RockCrabCalendar/RockCrabCalendar/Presentation/Core/Service/AdConfiguration.swift`
- `RockCrabCalendar/RockCrabCalendar/Presentation/Core/Service/AdRemovalPurchaseManager.swift`
- `RockCrabCalendar/RockCrabCalendar/Presentation/Core/Service/BannerAdView.swift`
- `RockCrabCalendar/RockCrabCalendar/Presentation/Core/Service/InterstitialAdService.swift`
- `RockCrabCalendar/RockCrabCalendar/Presentation/Core/Service/UserScheduleAdCounter.swift`

## App Store Connect 할 일

- [ ] 인앱결제 상품 생성
  - 유형: 비소모성
  - 상품 ID: `rockcrabcalendar.remove_ads`
  - 가격: `3,900원`
- [ ] 상품명과 설명 입력
  - 예시 상품명: `광고 제거`
  - 예시 설명: `바위게캘린더에서 배너 및 전면 광고를 제거합니다.`
- [ ] 인앱결제 심사 정보 입력
- [ ] 앱 버전 제출 시 인앱결제 상품을 함께 연결
- [ ] Sandbox 계정 또는 TestFlight로 구매/복원 확인

## AdMob 할 일

- [ ] 바위게캘린더 앱 등록 상태 확인
- [ ] 배너 광고 단위가 활성 상태인지 확인
- [ ] 전면 광고 단위가 활성 상태인지 확인
- [ ] 앱 스토어 등록 앱과 AdMob 앱 연결 상태 확인
- [ ] `app-ads.txt` 상태 확인
  - 루트 URL: `https://yuseongchoi.github.io/app-ads.txt`
  - 필요 라인: `google.com, pub-4795000952052288, DIRECT, f08c47fec0942fa0`

## TestFlight 확인 항목

- [ ] 무료 사용자 상태에서 하단 배너가 표시되는지 확인
- [ ] 개인 일정/일정 기록 신규 생성 합산 5회 이후 전면 광고가 표시되는지 확인
- [ ] 개인 일정 수정, QWER 일정 추가/수정, 일정 기록 수정에서는 전면 광고 카운트가 증가하지 않는지 확인
- [ ] 광고 제거 구매 후 하단 배너가 사라지는지 확인
- [ ] 광고 제거 구매 후 전면 광고가 더 이상 표시되지 않는지 확인
- [ ] 앱 재실행 후에도 광고 제거 상태가 유지되는지 확인
- [ ] 구매 복원 후 광고 제거 상태가 적용되는지 확인
- [ ] 네트워크가 불안정할 때 앱 사용 흐름이 막히지 않는지 확인

## 릴리즈 전 주의사항

- App Store Connect의 인앱결제 상품 ID가 코드의 `rockcrabcalendar.remove_ads`와 반드시 일치해야 합니다.
- AdMob 운영 광고는 실제 앱 심사/배포 상태에 따라 바로 노출되지 않을 수 있습니다.
- Debug 환경에서는 테스트 광고 ID를 사용하므로 운영 광고 노출 여부는 Release/TestFlight 기준으로 확인해야 합니다.
- Debug 환경의 광고 제거 구매 테스트 버튼은 `RockCrabCalendar.storekit`의 로컬 상품으로 StoreKit 결제 시트를 표시합니다.
- Debug 환경의 광고 제거 로컬 적용/해제 버튼은 StoreKit 결제 없이 광고 제거 상태만 변경하는 보조 테스트 기능입니다.
- 광고 제거 구매가 승인되지 않은 상태에서 앱 버전을 제출하면 심사 또는 배포 단계에서 막힐 수 있습니다.
