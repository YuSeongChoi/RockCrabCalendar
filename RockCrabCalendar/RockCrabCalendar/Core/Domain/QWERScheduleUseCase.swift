//
//  QWERScheduleUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Repository abstraction for QWER schedules to enable DI and testing.
protocol QWERScheduleRepository {
    func fetchSchedule() async throws -> [QWERScheduleItem]
    func saveSchedule(_ schedule: QWERScheduleItem) async throws
    func updateSchedule(_ schedule: QWERScheduleItem) async throws
    func deleteSchedule(_ schedule: QWERScheduleItem) async throws
    func fetchLocalOnly() async -> [QWERScheduleItem]
    func saveLocalSchedule(_ item: QWERScheduleItem) async
    func updateLocalSchedule(_ item: QWERScheduleItem) async
    func deleteLocalSchedule(_ item: QWERScheduleItem) async
    func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool
}

// Use-case layer for QWER schedules, isolating ViewModel from storage details.
struct QWERScheduleUseCase {
    private let repository: QWERScheduleRepository

    // Compose with a repository (Firestore/UserDefaults, mock, etc).
    init(repository: QWERScheduleRepository) {
        self.repository = repository
    }

    // Fetch remote + local merged schedules.
    func fetchAll() async throws -> [QWERScheduleItem] {
        try await repository.fetchSchedule()
    }

    // Create or upsert a remote schedule.
    func add(_ schedule: QWERScheduleItem) async throws {
        try await repository.saveSchedule(schedule)
    }

    // Update a remote schedule.
    func update(_ schedule: QWERScheduleItem) async throws {
        try await repository.updateSchedule(schedule)
    }

    // Delete a remote schedule.
    func delete(_ schedule: QWERScheduleItem) async throws {
        try await repository.deleteSchedule(schedule)
    }

    // Fetch local-only schedules.
    func fetchLocalOnly() async -> [QWERScheduleItem] {
        await repository.fetchLocalOnly()
    }

    // Save a local-only schedule.
    func addLocal(_ item: QWERScheduleItem) async {
        await repository.saveLocalSchedule(item)
    }

    // Update a local-only schedule.
    func updateLocal(_ item: QWERScheduleItem) async {
        await repository.updateLocalSchedule(item)
    }

    // Delete a local-only schedule.
    func deleteLocal(_ item: QWERScheduleItem) async {
        await repository.deleteLocalSchedule(item)
    }

    // Check whether the schedule is a local-only item.
    func isLocal(_ item: QWERScheduleItem) async -> Bool {
        await repository.isLocalSchedule(item)
    }
}
