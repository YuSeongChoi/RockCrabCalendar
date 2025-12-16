//
//  AnalyticsHelper.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/9/25.
//

import SwiftUI
import FirebaseAnalytics

struct AnalyticsHelper {
    static func logEvent(eventName: String, parameters: [String: Any]) {
        #if RELEASE
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }
}
