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

extension View {
    // 파이어베이스 로그 체크용
    func sendFirebaseLog(name: String) -> some View {
        self.onAppear {
            #if RELEASE
            Analytics.logEvent("screen_name", parameters: ["screen_name" : name])
            #endif
        }
    }
}
