//
//  AnalyticsHelper.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/9/25.
//

import FirebaseAnalytics
import Foundation
import RockCrabDomain

struct AnalyticsHelper {
    static func logEvent(eventName: String, parameters: [String: Any]) {
        #if RELEASE
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }

    static func logScreen(
        screenName: String,
        label: String,
        parameters: [String: Any] = [:]
    ) {
        logEvent(
            eventName: "screen_view_detail",
            parameters: parameters.merging([
                "screen_name": screenName,
                "label": label
            ]) { _, new in new }
        )
    }

    static func logAction(
        actionName: String,
        label: String,
        parameters: [String: Any] = [:]
    ) {
        logEvent(
            eventName: actionName,
            parameters: parameters.merging([
                "label": label
            ]) { _, new in new }
        )
    }
}

extension ScheduleEditKind {
    var analyticsLabel: String {
        switch self {
        case .qwer:
            return "QWER"
        case .user:
            return "개인"
        }
    }
}

extension ScheduleEditMode {
    var analyticsModeLabel: String {
        switch self {
        case .create:
            return "추가"
        case .editQWER, .editUser:
            return "수정"
        }
    }
}

extension ScheduleRecord.LinkedScheduleKind {
    var analyticsLabel: String {
        switch self {
        case .qwer:
            return "QWER"
        case .user:
            return "개인"
        }
    }
}
