import XCTest
@testable import RockCrabDomain

final class QWERScheduleItemMemberOrderTests: XCTestCase {
    func testInitNormalizesMembersToFixedOrder() {
        let item = QWERScheduleItem(
            title: "테스트",
            date: QWERScheduleItem.simpleDateFormatter.date(from: "2026-03-31")!,
            place: "",
            members: [.R, .E, .Q, .W],
            category: .other
        )

        XCTAssertEqual(item.members, [.Q, .W, .E, .R])
    }

    func testDecodeNormalizesMembersToFixedOrder() throws {
        let data = """
        {
          "id": "B56172ED-37CE-43A5-9A13-11B8545832D3",
          "title": "테스트",
          "date": 764035200,
          "time": "",
          "isAllDay": true,
          "timeStatus": "allDay",
          "place": "",
          "shouldNotify": false,
          "members": ["R", "Q", "E", "W"],
          "category": "기타"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(QWERScheduleItem.self, from: data)

        XCTAssertEqual(decoded.members, [.Q, .W, .E, .R])
    }
}
