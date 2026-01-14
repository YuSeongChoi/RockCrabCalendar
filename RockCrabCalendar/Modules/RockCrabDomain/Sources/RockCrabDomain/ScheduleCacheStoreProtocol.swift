//
//  ScheduleCacheStoreProtocol.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import Foundation

public protocol ScheduleCacheStoreProtocol {
    func loadCachedSchedules() -> [QWERScheduleItem]?
    func saveCachedSchedules(_ schedules: [QWERScheduleItem])
    func loadLastFetchDate() -> Date?
    func saveLastFetchDate(_ date: Date)
    func loadActiveCategories() -> Set<ScheduleCategory>?
    func saveActiveCategories(_ categories: Set<ScheduleCategory>)
}
