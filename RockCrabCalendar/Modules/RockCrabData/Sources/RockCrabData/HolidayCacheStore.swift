//
//  HolidayCacheStore.swift
//  RockCrabCalendar
//
//  UserDefaults-backed cache metadata for holiday data.
//

import Foundation
import RockCrabShared

public struct HolidayCacheStore {
    private let store: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    public func loadCachedYears() -> Set<Int> {
        Set(store.array(forKey: AppStorageKeys.holidayCacheYears) as? [Int] ?? [])
    }

    public func saveCachedYears(_ years: Set<Int>) {
        store.set(Array(years).sorted(), forKey: AppStorageKeys.holidayCacheYears)
    }

    public func loadBaseYear() -> Int {
        store.integer(forKey: AppStorageKeys.holidayCacheBaseYear)
    }

    public func saveBaseYear(_ year: Int) {
        store.set(year, forKey: AppStorageKeys.holidayCacheBaseYear)
    }
}
