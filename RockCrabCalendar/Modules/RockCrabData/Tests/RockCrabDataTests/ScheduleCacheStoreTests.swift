import XCTest
import RockCrabDomain
import RockCrabShared
@testable import RockCrabData

final class ScheduleCacheStoreTests: XCTestCase {
    private var suite: UserDefaults!
    private var store: ScheduleCacheStore!

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "ScheduleCacheStoreTests")
        suite.removePersistentDomain(forName: "ScheduleCacheStoreTests")
        store = ScheduleCacheStore(userDefaults: suite)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: "ScheduleCacheStoreTests")
        suite = nil
        store = nil
        super.tearDown()
    }

    func testClearScheduleCacheRemovesCachedSchedulesAndLastFetchDate() {
        let sample = QWERScheduleItem(
            title: "테스트",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            place: "서울",
            shouldNotify: false,
            members: [.Q],
            category: .other
        )
        let now = Date()

        store.saveCachedSchedules([sample])
        store.saveLastFetchDate(now)

        XCTAssertNotNil(store.loadCachedSchedules())
        XCTAssertNotNil(store.loadLastFetchDate())

        store.clearScheduleCache()

        XCTAssertNil(store.loadCachedSchedules())
        XCTAssertNil(store.loadLastFetchDate())
    }

    func testSaveCachedSchedulesPreservesNotificationLeadTime() {
        let sample = QWERScheduleItem(
            title: "알림 일정",
            date: Date(timeIntervalSince1970: 0),
            time: "",
            isAllDay: false,
            startTime: QWERScheduleItem.simpleTimeFormatter.date(from: "18:00"),
            endTime: nil,
            place: "서울",
            shouldNotify: true,
            notificationLeadTime: .thirtyMinutes,
            members: [.Q],
            category: .other
        )

        store.saveCachedSchedules([sample])

        let loaded = store.loadCachedSchedules()
        XCTAssertEqual(loaded?.first?.notificationLeadTime, .thirtyMinutes)
    }
}
