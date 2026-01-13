//
//  HolidayRepositoryTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2025/01/09.
//

import XCTest
@testable import RockCrabCalendar

final class HolidayRepositoryTests: XCTestCase {
    func testFetchHolidaysReturnsNilWhenCacheIsValid() async throws {
        let cache = MockHolidayCacheDataSource()
        cache.baseYear = 2024
        cache.cachedYears = [2023, 2024, 2025]
        let remote = MockHolidayRemoteDataSource()
        let repository = HolidayRepository(cacheStore: cache, remote: remote)

        let result = try await repository.fetchHolidaysIfNeeded(baseYear: 2024)
        let callCount = await remote.callCount

        XCTAssertNil(result)
        XCTAssertEqual(callCount, 0)
    }

    func testFetchHolidaysMapsToDomainModel() async throws {
        let cache = MockHolidayCacheDataSource()
        let remote = MockHolidayRemoteDataSource()
        await remote.setResponses([
            2023: [HolidayItemJSON(locdate: 20230101, dateName: "NY", isHoliday: "Y")],
            2024: [HolidayItemJSON(locdate: 20240101, dateName: "NY", isHoliday: "Y")],
            2025: [HolidayItemJSON(locdate: 20250101, dateName: "NY", isHoliday: "Y")]
        ])
        let repository = HolidayRepository(cacheStore: cache, remote: remote)

        let result = try await repository.fetchHolidaysIfNeeded(baseYear: 2024)

        XCTAssertEqual(result?.count, 3)
        XCTAssertEqual(result?.first?.date, "2023-01-01")
        XCTAssertEqual(cache.baseYear, 2024)
        XCTAssertEqual(cache.cachedYears, [2023, 2024, 2025])
    }
}

// MARK: - Test doubles
final class MockHolidayCacheDataSource: HolidayCacheDataSource {
    var baseYear: Int?
    var cachedYears: Set<Int> = []

    func loadBaseYear() -> Int? { baseYear }
    func loadCachedYears() -> Set<Int> { cachedYears }
    func saveBaseYear(_ year: Int) { baseYear = year }
    func saveCachedYears(_ years: Set<Int>) { cachedYears = years }
}

actor MockHolidayRemoteDataSource: HolidayRemoteDataSource {
    private var responses: [Int: [HolidayItemJSON]] = [:]
    private(set) var callCount: Int = 0

    func setResponses(_ values: [Int: [HolidayItemJSON]]) {
        responses = values
    }

    func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON] {
        callCount += 1
        return responses[year] ?? []
    }
}
