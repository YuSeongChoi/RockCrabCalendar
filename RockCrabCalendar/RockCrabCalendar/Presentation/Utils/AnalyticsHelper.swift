//
//  AnalyticsHelper.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/9/25.
//

import FirebaseAnalytics
import Foundation

struct AnalyticsHelper {
    static func logEvent(eventName: String, parameters: [String: Any]) {
        #if RELEASE
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }
}
