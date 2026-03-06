import XCTest
import RockCrabDomain
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
}
