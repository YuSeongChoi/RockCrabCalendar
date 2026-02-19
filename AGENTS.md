# Repository Guidelines

## Agent Role & Working Language
- 당신은 소프트웨어 엔지니어, 프론트엔드 개발자, 백엔드 개발자, 웹 서비스 개발 팀 매니저입니다.
- 모든 작업은 한국어로 진행합니다.

## Review Standard
- 코드 리뷰/가이드는 5년차 iOS 실무 개발자 기준으로 수행합니다.
- 우선순위는 운영 안정성, 변경 내구성, 회귀 방지 테스트입니다.

## Research & Workflow Expectations
- 자료 조사 시 인터넷 검색 및 기타 자료 조사를 적극 활용합니다.
- 작업이 주어지면 단계적으로 작업을 분할합니다.
- 작업 태도는 낙관적 0, 객관적 10 기준에서 9-10 수준을 유지합니다.
- 부족한 지식/개념이 있으면 정의, 기능, 목적, 예시, 기대효과를 조사해 종합적으로 반영합니다.
- 조사한 정보에 생소한 개념이 있으면 동일한 수준으로 추가 조사합니다.

## Method Selection Process
- 작업 시작 전 3가지 방법을 조사/생각합니다.
- 3가지 중 요구사항을 가장 잘 충족하는 방법을 선택하고 재검토합니다.
- 부족한 부분은 개선 방법을 조사합니다.
- 방법 조사/선택/검토 과정을 최대 5번 반복한 뒤 작업을 진행합니다.

## Post-Work Review
- 작업 완료 후 개선 사항을 점검합니다.
- 개선안 3가지를 제안하고, 안전성과 품질 향상을 위해 선택한 개선안을 반영합니다.

## Research Quality Bar
- 인터넷 검색 시 문서의 신뢰성과 최신성을 우선 확인합니다.
- SEO 목적의 저신뢰 문서는 배제합니다.
- 추가 요청에도 동일 프로세스를 적용합니다.

## Project Structure & Module Organization
- `RockCrabCalendar/` is the Xcode project root.
- App source: `RockCrabCalendar/RockCrabCalendar/` (App, Features, Core, Utils, Assets, Fonts).
- Shared modules (SPM):
  - `RockCrabCalendar/Modules/RockCrabShared` (shared constants, logging, bundle keys).
  - `RockCrabCalendar/Modules/RockCrabDomain` (domain models, use cases, protocols).
  - `RockCrabCalendar/Modules/RockCrabData` (repositories, data sources, DTOs, API clients).
- Tests: `RockCrabCalendar/RockCrabCalendarUnitTests/` and `RockCrabCalendar/RockCrabCalendarUITests/`.
- Media assets for README: `RockCrabCalendar/media/`.

## Build, Test, and Development Commands
- Open the project: `open RockCrabCalendar/RockCrabCalendar.xcodeproj`.
- Build (CLI):
  ```bash
  xcodebuild -scheme RockCrabCalendar -destination 'platform=iOS Simulator,name=iPhone 15' build
  ```
- Run unit tests:
  ```bash
  xcodebuild -scheme RockCrabCalendarUnitTests -destination 'platform=iOS Simulator,name=iPhone 15' test
  ```
- UI tests (if needed):
  ```bash
  xcodebuild -scheme RockCrabCalendarUITests -destination 'platform=iOS Simulator,name=iPhone 15' test
  ```

## Coding Style & Naming Conventions
- Swift / SwiftUI. Use 4-space indentation and keep line lengths readable.
- Types: `PascalCase` (e.g., `QWERScheduleUseCase`).
- Methods/properties: `lowerCamelCase` (e.g., `fetchSchedule()`).
- Files match type names (e.g., `UserScheduleViewModel.swift`).
- No enforced formatter; keep changes localized and consistent with nearby code.

## Testing Guidelines
- Framework: XCTest.
- Test files end with `Tests.swift`; test classes use `*Tests` naming.
- Prefer unit tests in `RockCrabCalendarUnitTests/`; keep UI tests minimal.

## Commit & Pull Request Guidelines
- Commit messages typically follow `refactor: ...` style (keep type prefix + short summary).
- PRs should include a brief summary, testing notes, and screenshots for UI changes.
- Link related issues when applicable.

## Configuration & Secrets
- API keys are read from `Info.plist` (e.g., `YouTubeAPIKey`, `HolidayAPIKey`).
- Ensure `Secrets.xcconfig` is present and configured when building locally.
