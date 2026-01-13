//
//  QWERScheduleRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Remote data source contract for QWER schedules.
protocol QWERScheduleRemoteDataSource {
    func fetchSchedules() async throws -> [QWERScheduleItem]
    func saveSchedule(_ schedule: QWERScheduleItem) async throws
    func updateSchedule(_ schedule: QWERScheduleItem) async throws
    func updateSchedules(_ schedules: [QWERScheduleItem]) async throws
    func deleteSchedule(_ schedule: QWERScheduleItem) async throws
}
