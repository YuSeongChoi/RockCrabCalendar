//
//  ScheduleCacheStore.swift
//  RockCrabCalendar
//
//  Schedule cache/accessor for UserDefaults-backed storage.
//

import Foundation
import RockCrabShared
import RockCrabDomain

public struct ScheduleCacheStore: ScheduleCacheStoreProtocol {
    private let store: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    public func loadCachedSchedules() -> [QWERScheduleItem]? {
        guard let data = store.data(forKey: AppStorageKeys.qwerScheduleCacheData),
              let decoded = try? JSONDecoder().decode([QWERScheduleItem].self, from: data) else {
            return nil
        }
        return decoded
    }

    public func saveCachedSchedules(_ schedules: [QWERScheduleItem]) {
        if let data = try? JSONEncoder().encode(schedules) {
            store.set(data, forKey: AppStorageKeys.qwerScheduleCacheData)
        }
    }

    public func loadLastFetchDate() -> Date? {
        store.object(forKey: AppStorageKeys.qwerScheduleLastFetchDate) as? Date
    }

    public func saveLastFetchDate(_ date: Date) {
        store.set(date, forKey: AppStorageKeys.qwerScheduleLastFetchDate)
    }

    public func loadActiveCategories() -> Set<ScheduleCategory>? {
        guard let raw = store.array(forKey: AppStorageKeys.activeScheduleCategories) as? [String] else {
            return nil
        }
        let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
        return decoded.isEmpty ? nil : Set(decoded)
    }

    public func saveActiveCategories(_ categories: Set<ScheduleCategory>) {
        let raw = categories.map { $0.rawValue }
        store.set(raw, forKey: AppStorageKeys.activeScheduleCategories)
    }
}
