import XCTest
@testable import RockCrabCalendar

final class AppCompositionSmokeTests: XCTestCase {
    func testConfiguredMockEnvironmentBuildsComposition() {
        let testDefaults = UserDefaults(suiteName: "AppCompositionSmokeTests")!
        defer { testDefaults.removePersistentDomain(forName: "AppCompositionSmokeTests") }

        let environment = AppEnvironment.configured(mode: .mock, userDefaults: testDefaults)

        XCTAssertNotNil(environment.qwerScheduleUseCase)
        XCTAssertNotNil(environment.userScheduleUseCase)
        XCTAssertNotNil(environment.holidayUseCase)
        XCTAssertNotNil(environment.youTubeUseCase)
    }
}
