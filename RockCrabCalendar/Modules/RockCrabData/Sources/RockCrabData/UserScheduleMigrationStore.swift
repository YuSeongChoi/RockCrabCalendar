//
//  UserScheduleMigrationStore.swift
//  RockCrabCalendar
//
//  Stores migration flags for user schedules.
//

import Foundation
import RockCrabDomain
import RockCrabShared

public struct UserScheduleMigrationStore: UserScheduleMigrationStoreProtocol {
    private let store: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    public func isLegacyTimeMigrationDone() -> Bool {
        store.bool(forKey: AppStorageKeys.userScheduleLegacyTimeMigration)
    }

    public func markLegacyTimeMigrationDone() {
        store.set(true, forKey: AppStorageKeys.userScheduleLegacyTimeMigration)
    }
}
