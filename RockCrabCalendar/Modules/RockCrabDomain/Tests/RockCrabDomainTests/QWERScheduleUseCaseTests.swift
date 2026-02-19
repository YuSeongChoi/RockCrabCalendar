import XCTest
@testable import RockCrabDomain

private struct RepositoryMock: QWERScheduleRepository {
    func fetchSchedule() async throws -> [QWERScheduleItem] { [] }
    func saveSchedule(_ schedule: QWERScheduleItem) async throws {}
    func updateSchedule(_ schedule: QWERScheduleItem) async throws {}
    func deleteSchedule(_ schedule: QWERScheduleItem) async throws {}
    func fetchLocalOnly() async -> [QWERScheduleItem] { [] }
    func saveLocalSchedule(_ item: QWERScheduleItem) async {}
    func updateLocalSchedule(_ item: QWERScheduleItem) async {}
    func deleteLocalSchedule(_ item: QWERScheduleItem) async {}
    func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool { false }
}

private final class CacheStoreMock: ScheduleCacheStoreProtocol {
    var lastFetchDate: Date?

    func loadCachedSchedules() -> [QWERScheduleItem]? { nil }
    func saveCachedSchedules(_ schedules: [QWERScheduleItem]) {}
    func loadLastFetchDate() -> Date? { lastFetchDate }
    func saveLastFetchDate(_ date: Date) { lastFetchDate = date }
    func loadActiveCategories() -> Set<ScheduleCategory>? { nil }
    func saveActiveCategories(_ categories: Set<ScheduleCategory>) {}
}

final class QWERScheduleUseCaseTests: XCTestCase {
    private let useCase = QWERScheduleUseCase(repository: RepositoryMock())

    func testShouldRefreshReturnsTrueWhenForced() {
        let store = CacheStoreMock()
        store.lastFetchDate = Date()

        let result = useCase.shouldRefresh(
            cacheStore: store,
            now: Date(),
            cacheTTLHours: 24,
            force: true
        )

        XCTAssertTrue(result)
    }

    func testShouldRefreshReturnsFalseWithinTTL() {
        let now = Date()
        let store = CacheStoreMock()
        store.lastFetchDate = Calendar.current.date(byAdding: .hour, value: -2, to: now)

        let result = useCase.shouldRefresh(
            cacheStore: store,
            now: now,
            cacheTTLHours: 24,
            force: false
        )

        XCTAssertFalse(result)
    }

    func testShouldRefreshReturnsTrueAfterTTL() {
        let now = Date()
        let store = CacheStoreMock()
        store.lastFetchDate = Calendar.current.date(byAdding: .hour, value: -30, to: now)

        let result = useCase.shouldRefresh(
            cacheStore: store,
            now: now,
            cacheTTLHours: 24,
            force: false
        )

        XCTAssertTrue(result)
    }
}
