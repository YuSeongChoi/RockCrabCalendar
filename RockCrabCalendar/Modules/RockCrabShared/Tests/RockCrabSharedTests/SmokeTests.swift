import XCTest
@testable import RockCrabShared

final class SmokeTests: XCTestCase {
    func testAppDateFormatsAreNonEmpty() {
        XCTAssertFalse(AppDateFormats.serverDay.isEmpty)
        XCTAssertFalse(AppDateFormats.monthTitle.isEmpty)
    }
}
