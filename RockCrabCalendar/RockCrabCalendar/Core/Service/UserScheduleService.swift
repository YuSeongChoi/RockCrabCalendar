//
//  UserScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/29/25.
//

import Foundation

// Repository that composes the local data source for user schedules.
actor UserScheduleService: ScheduleServiceProtocol, UserScheduleRepository {
    typealias Schedule = UserScheduleItem

    private let local: UserScheduleLocalDataSource

    init(local: UserScheduleLocalDataSource = UserDefaultsUserScheduleLocalDataSource()) {
        self.local = local
    }

    // Convenience for test injection.
    init(userDefaults: UserDefaults) {
        self.local = UserDefaultsUserScheduleLocalDataSource(userDefaults: userDefaults)
    }

    // MARK: - CRUD
    func saveSchedule(_ schedule: Schedule) async throws {
        try await local.saveSchedule(schedule)
    }

    func updateSchedule(_ schedule: Schedule) async throws {
        try await local.updateSchedule(schedule)
    }

    /// 전체 저장
    func updateSchedule(_ schedules: [Schedule]) async throws {
        try await local.updateSchedule(schedules)
    }

    func deleteSchedule(_ schedule: Schedule) async throws {
        try await local.deleteSchedule(schedule)
    }

    func fetchSchedule() async throws -> [Schedule] {
        try await local.fetchSchedule()
    }
}
