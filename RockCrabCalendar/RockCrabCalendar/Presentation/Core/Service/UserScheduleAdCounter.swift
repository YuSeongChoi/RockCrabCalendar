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

    func shouldPresentAfterRecordingCreation() -> Bool {
        let nextCount = userDefaults.integer(forKey: AppStorageKeys.userScheduleAdCreationCount) + 1
        userDefaults.set(nextCount, forKey: AppStorageKeys.userScheduleAdCreationCount)
        return nextCount >= triggerCount
    }

    func resetAfterPresentingInterstitial() {
        userDefaults.set(0, forKey: AppStorageKeys.userScheduleAdCreationCount)
    }
}
