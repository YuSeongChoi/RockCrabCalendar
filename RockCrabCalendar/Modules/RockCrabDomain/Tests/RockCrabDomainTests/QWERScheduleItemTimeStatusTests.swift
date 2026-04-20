import XCTest
@testable import RockCrabDomain
import RockCrabShared

final class QWERScheduleItemTimeStatusTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AppGroupUserDefaults.shared.set("ko", forKey: AppStorageKeys.preferredLanguageCode)
    }

    func testLegacyTimeWithoutStartTimeDecodesAsTimedWithoutForcedEndTime() throws {
        let date = Date(timeIntervalSince1970: 1_740_000_000)
        let payload: [String: Any] = [
            "title": "레거시 일정",
            "date": date.timeIntervalSince1970,
            "time": "19:00",
            "isAllDay": false,
            "place": "",
            "shouldNotify": false,
            "members": ["Q"],
            "category": ScheduleCategory.other.rawValue
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try JSONDecoder().decode(QWERScheduleItem.self, from: data)

        XCTAssertEqual(decoded.timeStatus, .timed)
        XCTAssertNotNil(decoded.startTime)
        XCTAssertNil(decoded.endTime)
    }

    func testTimedWithOnlyStartTimeKeepsNilEndTime() {
        let start = QWERScheduleItem.simpleTimeFormatter.date(from: "18:30")
        let item = QWERScheduleItem(
            title: "시작만 있음",
            date: Date(),
            time: "",
            isAllDay: false,
            startTime: start,
            endTime: nil,
            timeStatus: .timed,
            place: "",
            members: [.Q],
            category: .other
        )

        XCTAssertEqual(item.timeStatus, .timed)
        XCTAssertNotNil(item.startTime)
        XCTAssertNil(item.endTime)
    }

    func testUnspecifiedWithoutAnyTimeFieldsStaysUnspecified() {
        let item = QWERScheduleItem(
            title: "시간 미정",
            date: Date(),
            time: "",
            isAllDay: false,
            startTime: nil,
            endTime: nil,
            timeStatus: .unspecified,
            place: "",
            members: [.Q],
            category: .other
        )

        XCTAssertEqual(item.timeStatus, .unspecified)
        XCTAssertFalse(item.isAllDay)
        XCTAssertNil(item.startTime)
        XCTAssertNil(item.endTime)
        XCTAssertEqual(item.displayTime, "시간 미정")
    }

    func testEnglishDisplayTimeIncludesKSTForTimedQWERSchedule() {
        AppGroupUserDefaults.shared.set("en", forKey: AppStorageKeys.preferredLanguageCode)
        let start = QWERScheduleItem.simpleTimeFormatter.date(from: "18:30")
        let item = QWERScheduleItem(
            title: "영어 시간 표기",
            date: Date(),
            time: "",
            isAllDay: false,
            startTime: start,
            endTime: nil,
            timeStatus: .timed,
            place: "",
            members: [.Q],
            category: .other
        )

        XCTAssertEqual(item.displayTime, "18:30 KST")
    }

    func testDecodePreservesNotificationLeadTime() throws {
        let date = Date(timeIntervalSince1970: 1_740_000_000)
        let payload: [String: Any] = [
            "title": "알림 일정",
            "date": date.timeIntervalSince1970,
            "time": "19:00",
            "isAllDay": false,
            "place": "",
            "shouldNotify": true,
            "notificationLeadTime": NotificationLeadTime.tenMinutes.rawValue,
            "members": ["Q"],
            "category": ScheduleCategory.other.rawValue
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try JSONDecoder().decode(QWERScheduleItem.self, from: data)

        XCTAssertEqual(decoded.notificationLeadTime, .tenMinutes)
    }
}
