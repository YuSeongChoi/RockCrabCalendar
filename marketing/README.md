# RockCrabCalendar Marketing

`marketing/`은 `RockCrabCalendar` 앱스토어 제출용 iPhone 스크린샷 시안을 담고 있습니다.

이번 버전은 `RockCrabCalendar/image` 폴더의 최신 시뮬레이터 캡처를 기준으로 다시 구성했습니다.

## 파일

- `index.html`: iPhone App Store 스크린샷 7장 페이지
- `ipad.html`: iPad App Store 스크린샷 7장 페이지
- `styles.css`: 라이트 톤 기반 마케팅 레이아웃
- `ipad.css`: iPad 제출용 마케팅 레이아웃
- `export-screenshots.mjs`: Playwright 기반 PNG export 스크립트
- `export-ipad-screenshots.mjs`: iPad PNG export 스크립트
- `exports/`: 원본 고해상도 export 결과
- `exports-appstore-1284x2778/`: App Store 제출 규격 결과
- `exports-ipad-appstore-2064x2752/`: iPad App Store 제출 규격 결과

## 사용 방법

```bash
cd /Users/yuseongchoi/Desktop/RockCrabCalendar/marketing
npm install
npm run export:iphone
npm run export:ipad
```

## 현재 화면 매핑

- Slide 1: `calendar.png`
- Slide 2: `qwer_schedule_filter.png`
- Slide 3: `schedule_list.png`
- Slide 4: `schedule_qwer_add.png`
- Slide 5: `schedule_private_add.png`
- Slide 6: `widget.png`
- Slide 7: `setting.png`

## iPad 화면 매핑

- Slide 1: `image/iPad/calendar.png`
- Slide 2: `image/iPad/qwer_schedule_filter.png`
- Slide 3: `image/iPad/schedule_list.png`
- Slide 4: `image/iPad/schedule_qwer_add.png`
- Slide 5: `image/iPad/schedule_private_add.png`
- Slide 6: `image/iPad/widget.png`
- Slide 7: `image/iPad/setting.png`
