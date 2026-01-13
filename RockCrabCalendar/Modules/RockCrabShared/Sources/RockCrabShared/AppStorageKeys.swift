//
//  AppStorageKeys.swift
//  RockCrabCalendar
//
//  Centralized UserDefaults keys to avoid typos and collisions.
//

import Foundation

public enum AppStorageKeys {
    public static let holidayCacheData = "holidayCacheData"
    public static let holidayCacheYears = "holidayCacheYears"
    public static let holidayCacheBaseYear = "holidayCacheBaseYear"

    public static let qwerScheduleCacheData = "cachedSchedules"
    public static let qwerScheduleLastFetchDate = "lastScheduleFetchDate"
    public static let activeScheduleCategories = "activeScheduleCategories"
    public static let qwerLocalSchedules = "localQWERSchedules"

    public static let userSchedules = "userSchedules"
    public static let userScheduleLegacyTimeMigration = "hasMigratedUserScheduleTimes"
}
