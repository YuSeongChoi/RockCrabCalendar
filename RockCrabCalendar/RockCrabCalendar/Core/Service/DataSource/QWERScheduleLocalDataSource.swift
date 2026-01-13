//
//  QWERScheduleLocalDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Local data source contract for QWER schedules.
protocol QWERScheduleLocalDataSource {
    func fetchLocalOnly() async -> [QWERScheduleItem]
    func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool
    func saveLocalSchedule(_ item: QWERScheduleItem) async
    func updateLocalSchedule(_ item: QWERScheduleItem) async
    func deleteLocalSchedule(_ item: QWERScheduleItem) async
}
