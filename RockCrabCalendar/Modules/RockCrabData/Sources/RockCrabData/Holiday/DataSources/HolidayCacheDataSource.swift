//
//  HolidayCacheDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Cache data source contract for holiday metadata.
public protocol HolidayCacheDataSource {
    func loadBaseYear() -> Int?
    func loadCachedYears() -> Set<Int>
    func saveBaseYear(_ year: Int)
    func saveCachedYears(_ years: Set<Int>)
}

// Holiday cache backed by HolidayCacheStore.
public struct HolidayCacheStoreDataSource: HolidayCacheDataSource {
    private let store: HolidayCacheStore

    public init(store: HolidayCacheStore = HolidayCacheStore()) {
        self.store = store
    }

    public func loadBaseYear() -> Int? { store.loadBaseYear() }
    public func loadCachedYears() -> Set<Int> { store.loadCachedYears() }
    public func saveBaseYear(_ year: Int) { store.saveBaseYear(year) }
    public func saveCachedYears(_ years: Set<Int>) { store.saveCachedYears(years) }
}
