//
//  HolidayRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Remote data source contract for holiday APIs.
protocol HolidayRemoteDataSource {
    func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON]
}

// Holiday API-backed remote data source.
struct HolidayAPIRemoteDataSource: HolidayRemoteDataSource {
    private let apiClient: HolidayAPIClient

    init(apiClient: HolidayAPIClient = HolidayAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON] {
        try await apiClient.fetchHolidayItems(year: year)
    }
}
