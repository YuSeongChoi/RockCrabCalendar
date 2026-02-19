import XCTest
@testable import RockCrabShared

final class AppConstantsTests: XCTestCase {
    func testAppStorageKeysAreStable() {
        XCTAssertEqual(AppStorageKeys.holidayCacheData, "holidayCacheData")
        XCTAssertEqual(AppStorageKeys.qwerLocalSchedules, "localQWERSchedules")
        XCTAssertEqual(AppStorageKeys.userSchedules, "userSchedules")
    }

    func testDateFormatsAreStable() {
        XCTAssertEqual(AppDateFormats.serverDay, "yyyy-MM-dd")
        XCTAssertEqual(AppDateFormats.holidayInput, "yyyyMMdd")
        XCTAssertEqual(AppDateFormats.hourMinute, "HH:mm")
    }
}
