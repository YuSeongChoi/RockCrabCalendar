//
//  UserScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/29/25.
//

import Foundation
import RockCrabDomain

// Repository that composes the local data source for user schedules.
public actor UserScheduleService: ScheduleServiceProtocol, UserScheduleRepository {
    public typealias Schedule = UserScheduleItem

    private let local: UserScheduleLocalDataSource

    public init(local: UserScheduleLocalDataSource = UserDefaultsUserScheduleLocalDataSource()) {
        self.local = local
    }

    // Convenience for test injection.
    public init(userDefaults: UserDefaults) {
        self.local = UserDefaultsUserScheduleLocalDataSource(userDefaults: userDefaults)
    }

    // MARK: - CRUD
    public func saveSchedule(_ schedule: Schedule) async throws {
        try await local.saveSchedule(schedule)
    }

    public func updateSchedule(_ schedule: Schedule) async throws {
        try await local.updateSchedule(schedule)
    }

    /// 전체 저장
    public func updateSchedule(_ schedules: [Schedule]) async throws {
        try await local.updateSchedule(schedules)
    }

    public func deleteSchedule(_ schedule: Schedule) async throws {
        try await local.deleteSchedule(schedule)
    }

    public func fetchSchedule() async throws -> [Schedule] {
        try await local.fetchSchedule()
    }
}
