//
//  UserDefaultsScheduleRecordStore.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation
import RockCrabDomain
import RockCrabShared

public enum ScheduleRecordStoreError: Error, Equatable {
    case encodingFailed
}

public final class UserDefaultsScheduleRecordStore: ScheduleRecordStoreProtocol {
    private let store: UserDefaults
    private let key: String

    public init(
        userDefaults: UserDefaults = AppGroupUserDefaults.shared,
        key: String = AppStorageKeys.scheduleRecords
    ) {
        self.store = userDefaults
        self.key = key
    }

    public func fetchRecords() throws -> [ScheduleRecord] {
        loadRecords().sorted {
            if $0.createdAt == $1.createdAt {
                return $0.updatedAt > $1.updatedAt
            }
            return $0.createdAt > $1.createdAt
        }
    }

    public func record(id: UUID) throws -> ScheduleRecord? {
        loadRecords().first { $0.id == id }
    }

    public func record(
        linkedTo scheduleID: UUID,
        kind: ScheduleRecord.LinkedScheduleKind
    ) throws -> ScheduleRecord? {
        let linkedKey = "\(kind.rawValue)-\(scheduleID.uuidString)"
        return loadRecords().first { $0.linkedScheduleKey == linkedKey }
    }

    public func saveRecord(_ record: ScheduleRecord) throws {
        var records = loadRecords()

        records.removeAll {
            $0.id == record.id || $0.linkedScheduleKey == record.linkedScheduleKey
        }
        records.append(record)

        try persist(records)
    }

    @discardableResult
    public func deleteRecord(id: UUID) throws -> ScheduleRecord? {
        var records = loadRecords()
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        let removed = records.remove(at: index)
        try persist(records)
        return removed
    }
}

private extension UserDefaultsScheduleRecordStore {
    func loadRecords() -> [ScheduleRecord] {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScheduleRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    func persist(_ records: [ScheduleRecord]) throws {
        do {
            let data = try JSONEncoder().encode(records)
            store.set(data, forKey: key)
        } catch {
            throw ScheduleRecordStoreError.encodingFailed
        }
    }
}
