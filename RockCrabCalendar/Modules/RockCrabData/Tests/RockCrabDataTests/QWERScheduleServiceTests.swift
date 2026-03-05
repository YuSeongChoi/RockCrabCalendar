import XCTest
import RockCrabDomain
@testable import RockCrabData

final class QWERScheduleServiceTests: XCTestCase {
    private var suite: UserDefaults!
    private var service: QWERScheduleService!
    private var remote: MockQWERScheduleRemoteDataSource!
    private let sampleDate = Date(timeIntervalSince1970: 0)

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "QWERScheduleServiceTests")
        suite.removePersistentDomain(forName: "QWERScheduleServiceTests")
        remote = MockQWERScheduleRemoteDataSource()
        let local = UserDefaultsQWERScheduleLocalDataSource(userDefaults: suite)
        service = QWERScheduleService(remote: remote, local: local)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: "QWERScheduleServiceTests")
        suite = nil
        service = nil
        remote = nil
        super.tearDown()
    }

    private func makeSchedule(title: String = "테스트") -> QWERScheduleItem {
        QWERScheduleItem(
            title: title,
            date: sampleDate,
            time: "",
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            place: "서울",
            shouldNotify: false,
            members: [.Q],
            category: .other
        )
    }

    func testSaveLocalAndFetchLocalOnly() async {
        let item = makeSchedule()
        await service.saveLocalSchedule(item)

        let locals = await service.fetchLocalOnly()
        XCTAssertEqual(locals.count, 1)
        XCTAssertEqual(locals.first?.title, item.title)
    }

    func testUpdateLocalReplacesByID() async {
        var item = makeSchedule(title: "원본")
        await service.saveLocalSchedule(item)

        item.title = "수정됨"
        await service.updateLocalSchedule(item)

        let locals = await service.fetchLocalOnly()
        XCTAssertEqual(locals.first?.title, "수정됨")
    }

    func testDeleteLocalRemovesItem() async {
        let item = makeSchedule(title: "삭제 대상")
        await service.saveLocalSchedule(item)

        await service.deleteLocalSchedule(item)
        let locals = await service.fetchLocalOnly()
        XCTAssertTrue(locals.isEmpty)
    }

    func testIsLocalScheduleMatchesStored() async {
        let item = makeSchedule()
        await service.saveLocalSchedule(item)

        let isLocal = await service.isLocalSchedule(item)
        XCTAssertTrue(isLocal)
    }

    func testFetchScheduleMergesRemoteAndLocal() async throws {
        let remoteItem = makeSchedule(title: "remote")
        let localItem = makeSchedule(title: "local")

        await remote.setSchedules([remoteItem])
        await service.saveLocalSchedule(localItem)

        let fetched = try await service.fetchSchedule()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.contains(where: { $0.title == "remote" }))
        XCTAssertTrue(fetched.contains(where: { $0.title == "local" }))
    }
}

actor MockQWERScheduleRemoteDataSource: QWERScheduleRemoteDataSource {
    private var schedules: [QWERScheduleItem] = []

    func setSchedules(_ items: [QWERScheduleItem]) {
        schedules = items
    }

    func fetchSchedules() async throws -> [QWERScheduleItem] {
        schedules
    }

    func saveSchedule(_ schedule: QWERScheduleItem) async throws {
        schedules.append(schedule)
    }

    func updateSchedule(_ schedule: QWERScheduleItem) async throws {
        if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[idx] = schedule
        }
    }

    func updateSchedules(_ schedules: [QWERScheduleItem]) async throws {
        self.schedules = schedules
    }

    func deleteSchedule(_ schedule: QWERScheduleItem) async throws {
        schedules.removeAll { $0.id == schedule.id }
    }
}
