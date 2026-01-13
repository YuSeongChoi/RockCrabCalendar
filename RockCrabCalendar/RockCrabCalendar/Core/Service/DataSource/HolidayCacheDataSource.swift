//
//  HolidayCacheDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Cache data source contract for holiday metadata.
protocol HolidayCacheDataSource {
    func loadBaseYear() -> Int?
    func loadCachedYears() -> Set<Int>
    func saveBaseYear(_ year: Int)
    func saveCachedYears(_ years: Set<Int>)
}

// Holiday cache backed by HolidayCacheStore.
struct HolidayCacheStoreDataSource: HolidayCacheDataSource {
    private let store: HolidayCacheStore

    init(store: HolidayCacheStore = HolidayCacheStore()) {
        self.store = store
    }

    func loadBaseYear() -> Int? { store.loadBaseYear() }
    func loadCachedYears() -> Set<Int> { store.loadCachedYears() }
    func saveBaseYear(_ year: Int) { store.saveBaseYear(year) }
    func saveCachedYears(_ years: Set<Int>) { store.saveCachedYears(years) }
}
