//
//  AppStorageKeys.swift
//  RockCrabCalendar
//
//  Centralized UserDefaults keys to avoid typos and collisions.
//

import Foundation

enum AppStorageKeys {
    static let holidayCacheData = "holidayCacheData"
    static let holidayCacheYears = "holidayCacheYears"
    static let holidayCacheBaseYear = "holidayCacheBaseYear"

    static let qwerScheduleCacheData = "cachedSchedules"
    static let qwerScheduleLastFetchDate = "lastScheduleFetchDate"
    static let activeScheduleCategories = "activeScheduleCategories"
    static let qwerLocalSchedules = "localQWERSchedules"

    static let userSchedules = "userSchedules"
    static let userScheduleLegacyTimeMigration = "hasMigratedUserScheduleTimes"
}
