//
//  UserScheduleLocalDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Local data source contract for user schedules.
protocol UserScheduleLocalDataSource {
    func fetchSchedule() async throws -> [UserScheduleItem]
    func saveSchedule(_ schedule: UserScheduleItem) async throws
    func updateSchedule(_ schedule: UserScheduleItem) async throws
    func updateSchedule(_ schedules: [UserScheduleItem]) async throws
    func deleteSchedule(_ schedule: UserScheduleItem) async throws
}
