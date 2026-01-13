//
//  HolidayRepository.swift
//  RockCrabCalendar
//
//  Orchestrates holiday fetching and cache metadata.
//

import Foundation
import RockCrabShared

// Concrete holiday repository (Data layer).
struct HolidayRepository: HolidayRepositoryProtocol {
    private let cacheStore: HolidayCacheDataSource
    private let remote: HolidayRemoteDataSource

    init(
        cacheStore: HolidayCacheDataSource = HolidayCacheStoreDataSource(),
        remote: HolidayRemoteDataSource = HolidayAPIRemoteDataSource()
    ) {
        self.cacheStore = cacheStore
        self.remote = remote
    }

    func fetchHolidaysIfNeeded(baseYear: Int) async throws -> [HolidayInfo]? {
        let targetYears = Set([baseYear - 1, baseYear, baseYear + 1])
        let cachedBaseYear = cacheStore.loadBaseYear()
        let cachedYears = cacheStore.loadCachedYears()
        if cachedBaseYear == baseYear, !cachedYears.isEmpty {
            return nil
        }

        var holidayByDate: [String: String] = [:]
        for year in targetYears.sorted() {
            let items = try await remote.fetchHolidayItems(year: year)
            let dtos = items.filter { $0.isHoliday == "Y" }
            for dto in dtos {
                let dateKey = formatHolidayDate(dto.locdate)
                if holidayByDate[dateKey] == nil {
                    holidayByDate[dateKey] = dto.dateName
                }
            }
        }

        let saveArray = holidayByDate
            .sorted { $0.key < $1.key }
            .map { HolidayInfo(date: $0.key, name: $0.value) }

        cacheStore.saveCachedYears(targetYears)
        cacheStore.saveBaseYear(baseYear)

        return saveArray
    }

    private func formatHolidayDate(_ raw: Int) -> String {
        let rawString = String(raw)
        let input = DateFormatter()
        input.calendar = Calendar(identifier: .gregorian)
        input.locale = Locale(identifier: "ko_KR")
        input.timeZone = TimeZone(identifier: "Asia/Seoul")
        input.dateFormat = AppDateFormats.holidayInput

        let output = DateFormatter()
        output.calendar = Calendar(identifier: .gregorian)
        output.locale = Locale(identifier: "ko_KR")
        output.timeZone = TimeZone(identifier: "Asia/Seoul")
        output.dateFormat = AppDateFormats.holidayOutput

        guard let date = input.date(from: rawString) else { return rawString }
        return output.string(from: date)
    }
}
