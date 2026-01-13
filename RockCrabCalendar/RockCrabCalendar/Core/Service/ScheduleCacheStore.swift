//
//  ScheduleCacheStore.swift
//  RockCrabCalendar
//
//  Schedule cache/accessor for UserDefaults-backed storage.
//

import Foundation
import RockCrabShared

struct ScheduleCacheStore {
    private let store: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    func loadCachedSchedules() -> [QWERScheduleItem]? {
        guard let data = store.data(forKey: AppStorageKeys.qwerScheduleCacheData),
              let decoded = try? JSONDecoder().decode([QWERScheduleItem].self, from: data) else {
            return nil
        }
        return decoded
    }

    func saveCachedSchedules(_ schedules: [QWERScheduleItem]) {
        if let data = try? JSONEncoder().encode(schedules) {
            store.set(data, forKey: AppStorageKeys.qwerScheduleCacheData)
        }
    }

    func loadLastFetchDate() -> Date? {
        store.object(forKey: AppStorageKeys.qwerScheduleLastFetchDate) as? Date
    }

    func saveLastFetchDate(_ date: Date) {
        store.set(date, forKey: AppStorageKeys.qwerScheduleLastFetchDate)
    }

    func loadActiveCategories() -> Set<ScheduleCategory>? {
        guard let raw = store.array(forKey: AppStorageKeys.activeScheduleCategories) as? [String] else {
            return nil
        }
        let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
        return decoded.isEmpty ? nil : Set(decoded)
    }

    func saveActiveCategories(_ categories: Set<ScheduleCategory>) {
        let raw = categories.map { $0.rawValue }
        store.set(raw, forKey: AppStorageKeys.activeScheduleCategories)
    }
}
