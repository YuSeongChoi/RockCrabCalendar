//
//  AppStorageKeys.swift
//  RockCrabCalendar
//
//  Centralized UserDefaults keys to avoid typos and collisions.
//

import Foundation

public enum AppStorageKeys {
    public static let preferredAppLanguage = "preferredAppLanguage"
    public static let preferredLanguageCode = "preferredLanguageCode"
    public static let appUpdateLastCheckedAt = "appUpdateLastCheckedAt"
    public static let appUpdateSnoozedVersion = "appUpdateSnoozedVersion"
    public static let appUpdateSnoozedUntil = "appUpdateSnoozedUntil"

    public static let holidayCacheData = "holidayCacheData"
    public static let holidayCacheYears = "holidayCacheYears"
    public static let holidayCacheBaseYear = "holidayCacheBaseYear"

    public static let qwerScheduleCacheData = "cachedSchedules"
    public static let qwerScheduleLastFetchDate = "lastScheduleFetchDate"
    public static let activeScheduleCategories = "activeScheduleCategories"
    public static let qwerLocalSchedules = "localQWERSchedules"

    public static let userSchedules = "userSchedules"
    public static let userScheduleLegacyTimeMigration = "hasMigratedUserScheduleTimes"

    public static let appGroupMigrationKeys: [String] = [
        preferredLanguageCode,
        preferredAppLanguage,
        appUpdateLastCheckedAt,
        appUpdateSnoozedVersion,
        appUpdateSnoozedUntil,
        holidayCacheData,
        holidayCacheYears,
        holidayCacheBaseYear,
        qwerScheduleCacheData,
        qwerScheduleLastFetchDate,
        activeScheduleCategories,
        qwerLocalSchedules,
        userSchedules,
        userScheduleLegacyTimeMigration
    ]
}
