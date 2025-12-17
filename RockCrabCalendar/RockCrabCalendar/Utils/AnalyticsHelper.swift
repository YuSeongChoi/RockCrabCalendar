//
//  AnalyticsHelper.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/9/25.
//

import SwiftUI
import FirebaseAnalytics
import os
import Foundation

struct AnalyticsHelper {
    static func logEvent(eventName: String, parameters: [String: Any]) {
        #if RELEASE
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }
}

enum LogCategory: String {
    case app = "App"
    case qwerService = "QWERService"
    case userService = "UserService"
    case scheduleVM = "ScheduleViewModel"
    case youtube = "YouTube"
    case notification = "Notification"
}

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "RockCrabCalendar"
    
    static func debug(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.debug("\(message, privacy: .public)")
    }
    
    static func info(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("\(message, privacy: .public)")
    }
    
    static func error(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.error("\(message, privacy: .public)")
    }
}
