//
//  UserScheduleUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabShared

// Repository abstraction for user schedules to enable DI and testing.
public protocol UserScheduleRepository {
    func fetchSchedule() async throws -> [UserScheduleItem]
    func saveSchedule(_ schedule: UserScheduleItem) async throws
    func updateSchedule(_ schedule: UserScheduleItem) async throws
    func deleteSchedule(_ schedule: UserScheduleItem) async throws
}

// Use-case layer for user schedules, isolating ViewModel from storage details.
public struct UserScheduleUseCase {
    private let repository: UserScheduleRepository

    // Compose with a repository (UserDefaults, mock, etc).
    public init(repository: UserScheduleRepository) {
        self.repository = repository
    }

    // Fetch all user schedules.
    public func fetchAll() async throws -> [UserScheduleItem] {
        try await repository.fetchSchedule()
    }

    // Create a user schedule.
    public func add(_ schedule: UserScheduleItem) async throws {
        try await repository.saveSchedule(schedule)
    }

    // Update a user schedule.
    public func update(_ schedule: UserScheduleItem) async throws {
        try await repository.updateSchedule(schedule)
    }

    // Delete a user schedule.
    public func delete(_ schedule: UserScheduleItem) async throws {
        try await repository.deleteSchedule(schedule)
    }

    // Migrate legacy time fields once and return whether a migration ran.
    public func migrateLegacyTimesIfNeeded(
        migrationStore: UserScheduleMigrationStoreProtocol
    ) async throws -> Bool {
        if migrationStore.isLegacyTimeMigrationDone() {
            return false
        }

        let items = try await repository.fetchSchedule()
        var updatedItems: [UserScheduleItem] = []

        for item in items {
            if !item.time.isEmpty && item.startTime == nil {
                var updated = item
                let formatter = DateFormatter()
                formatter.dateFormat = AppDateFormats.hourMinute
                formatter.locale = Locale(identifier: "ko_KR")
                if let parsed = formatter.date(from: item.time) {
                    updated.startTime = parsed
                    updated.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: parsed)
                    updated.isAllDay = false
                    updatedItems.append(updated)
                }
            }
        }

        if updatedItems.isEmpty {
            migrationStore.markLegacyTimeMigrationDone()
            return false
        }

        for updated in updatedItems {
            try await repository.updateSchedule(updated)
        }

        migrationStore.markLegacyTimeMigrationDone()
        return true
    }
}
