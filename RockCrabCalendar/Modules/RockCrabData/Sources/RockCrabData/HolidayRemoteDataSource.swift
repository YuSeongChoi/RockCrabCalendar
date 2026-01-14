//
//  HolidayRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Remote data source contract for holiday APIs.
public protocol HolidayRemoteDataSource {
    func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON]
}

// Holiday API-backed remote data source.
public struct HolidayAPIRemoteDataSource: HolidayRemoteDataSource {
    private let apiClient: HolidayAPIClient

    public init() {
        self.apiClient = HolidayAPIClient()
    }

    init(apiClient: HolidayAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchHolidayItems(year: Int) async throws -> [HolidayItemJSON] {
        try await apiClient.fetchHolidayItems(year: year)
    }
}
