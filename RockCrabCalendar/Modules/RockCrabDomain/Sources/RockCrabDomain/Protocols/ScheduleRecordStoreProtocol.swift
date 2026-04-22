//
//  ScheduleRecordStoreProtocol.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation

public protocol ScheduleRecordStoreProtocol {
    func fetchRecords() throws -> [ScheduleRecord]
    func record(id: UUID) throws -> ScheduleRecord?
    func record(
        linkedTo scheduleID: UUID,
        kind: ScheduleRecord.LinkedScheduleKind
    ) throws -> ScheduleRecord?
    func saveRecord(_ record: ScheduleRecord) throws
    @discardableResult
    func deleteRecord(id: UUID) throws -> ScheduleRecord?
}
