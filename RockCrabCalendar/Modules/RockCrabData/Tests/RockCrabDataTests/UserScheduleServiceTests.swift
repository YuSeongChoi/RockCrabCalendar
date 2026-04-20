import XCTest
import RockCrabDomain
import RockCrabShared
@testable import RockCrabData

final class UserScheduleServiceTests: XCTestCase {
    private var suite: UserDefaults!
    private var service: UserScheduleService!

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "UserScheduleServiceTests")
        suite.removePersistentDomain(forName: "UserScheduleServiceTests")
        service = UserScheduleService(userDefaults: suite)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: "UserScheduleServiceTests")
        suite = nil
        service = nil
        super.tearDown()
    }

    func testSaveAndFetch() async throws {
        let item = UserScheduleItem(
            title: "테스트 일정",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            place: "서울"
        )
        try await service.saveSchedule(item)
        let fetched = try await service.fetchSchedule()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "테스트 일정")
    }

    func testUpdateScheduleReplacesExisting() async throws {
        var item = UserScheduleItem(
            title: "원본",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            place: "서울"
        )
        try await service.saveSchedule(item)

        item.title = "수정"
        try await service.updateSchedule(item)

        let fetched = try await service.fetchSchedule()
        XCTAssertEqual(fetched.first?.title, "수정")
    }

    func testDeleteScheduleRemovesItem() async throws {
        let item = UserScheduleItem(
            title: "삭제 대상",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            place: "서울"
        )
        try await service.saveSchedule(item)
        try await service.deleteSchedule(item)

        let fetched = try await service.fetchSchedule()
        XCTAssertTrue(fetched.isEmpty)
    }

    func testSaveAndFetchPreservesNotificationLeadTime() async throws {
        let item = UserScheduleItem(
            title: "알림 일정",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            isAllDay: false,
            startTime: Date(timeIntervalSince1970: 3_600),
            endTime: Date(timeIntervalSince1970: 7_200),
            place: "서울",
            shouldNotify: true,
            notificationLeadTime: .fiveMinutes
        )

        try await service.saveSchedule(item)
        let fetched = try await service.fetchSchedule()

        XCTAssertEqual(fetched.first?.notificationLeadTime, .fiveMinutes)
    }
}
