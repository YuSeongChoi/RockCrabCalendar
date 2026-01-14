//
//  AppLogger.swift
//  RockCrabCalendar
//
//  Shared logging utilities for app + modules.
//

import Foundation
import os

public enum LogCategory: String {
    case app = "App"
    case qwerService = "QWERService"
    case userService = "UserService"
    case scheduleVM = "ScheduleViewModel"
    case youtube = "YouTube"
    case notification = "Notification"
}

public struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "RockCrabCalendar"

    public static func debug(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.debug("\(message, privacy: .public)")
    }

    public static func info(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.info("\(message, privacy: .public)")
    }

    public static func error(_ message: String, category: LogCategory = .app) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.error("\(message, privacy: .public)")
    }
}
