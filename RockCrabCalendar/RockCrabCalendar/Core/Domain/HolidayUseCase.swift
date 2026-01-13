//
//  HolidayUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Repository abstraction for holiday fetching to enable DI and testing.
protocol HolidayRepositoryProtocol {
    func fetchHolidaysIfNeeded(baseYear: Int) async throws -> Data?
}

// Use-case layer for holiday sync.
struct HolidayUseCase {
    private let repository: HolidayRepositoryProtocol

    // Compose with a repository (API client + cache, mock, etc).
    init(repository: HolidayRepositoryProtocol) {
        self.repository = repository
    }

    // Fetch holidays for a base year if cache is stale.
    func fetchIfNeeded(baseYear: Int) async throws -> Data? {
        try await repository.fetchHolidaysIfNeeded(baseYear: baseYear)
    }
}
