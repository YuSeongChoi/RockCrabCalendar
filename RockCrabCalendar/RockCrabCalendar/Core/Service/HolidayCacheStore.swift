//
//  HolidayCacheStore.swift
//  RockCrabCalendar
//
//  UserDefaults-backed cache metadata for holiday data.
//

import Foundation

struct HolidayCacheStore {
    private let store: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    func loadCachedYears() -> Set<Int> {
        Set(store.array(forKey: AppStorageKeys.holidayCacheYears) as? [Int] ?? [])
    }

    func saveCachedYears(_ years: Set<Int>) {
        store.set(Array(years).sorted(), forKey: AppStorageKeys.holidayCacheYears)
    }

    func loadBaseYear() -> Int {
        store.integer(forKey: AppStorageKeys.holidayCacheBaseYear)
    }

    func saveBaseYear(_ year: Int) {
        store.set(year, forKey: AppStorageKeys.holidayCacheBaseYear)
    }
}
