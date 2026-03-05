//
//  NoopQWERScheduleRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/03/05.
//

import Foundation
import RockCrabDomain

// Null-object remote for local-only/test contexts.
public struct NoopQWERScheduleRemoteDataSource: QWERScheduleRemoteDataSource {
    public init() {}

    public func fetchSchedules() async throws -> [QWERScheduleItem] { [] }

    public func saveSchedule(_ schedule: QWERScheduleItem) async throws {}

    public func updateSchedule(_ schedule: QWERScheduleItem) async throws {}

    public func updateSchedules(_ schedules: [QWERScheduleItem]) async throws {}

    public func deleteSchedule(_ schedule: QWERScheduleItem) async throws {}
}
