import XCTest
@testable import RockCrabDomain

final class SmokeTests: XCTestCase {
    func testQWERMemberRawValueRoundTrip() {
        let member = QWERMember.Q
        XCTAssertEqual(QWERMember(rawValue: member.rawValue), member)
    }
}
