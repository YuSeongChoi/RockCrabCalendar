//
//  UserScheduleAdCounter.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/05/06.
//

import Foundation
import RockCrabShared

struct UserScheduleAdCounter {
    private let userDefaults: UserDefaults
    private let triggerCount: Int

    init(
        userDefaults: UserDefaults = AppGroupUserDefaults.shared,
        triggerCount: Int = AdConfiguration.interstitialTriggerCount
    ) {
        self.userDefaults = userDefaults
        self.triggerCount = max(triggerCount, 1)
    }

    func recordContentCreation() -> Bool {
        let nextCount = userDefaults.integer(forKey: AppStorageKeys.userScheduleAdCreationCount) + 1
        let shouldPresent = nextCount >= triggerCount
        userDefaults.set(shouldPresent ? 0 : nextCount, forKey: AppStorageKeys.userScheduleAdCreationCount)
        return shouldPresent
    }
}
