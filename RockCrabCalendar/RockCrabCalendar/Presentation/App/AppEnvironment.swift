//
//  AppEnvironment.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/09.
//

import Foundation
import RockCrabDomain

// Central DI container for assembling live dependencies.
final class AppEnvironment: ObservableObject {
    enum RuntimeMode: String {
        case live
        case localOnly = "local-only"
        case mock

        static func resolved(
            processInfo: ProcessInfo = .processInfo
        ) -> RuntimeMode {
            let arguments = Set(processInfo.arguments)
            if arguments.contains("--mock") { return .mock }
            if arguments.contains("--local-only") { return .localOnly }

            let env = processInfo.environment["APP_ENV"]?.lowercased()
            return RuntimeMode(rawValue: env ?? "") ?? .live
        }
    }

    let qwerScheduleUseCase: QWERScheduleUseCase
    let userScheduleUseCase: UserScheduleUseCase
    let holidayUseCase: HolidayUseCase
    let youTubeUseCase: YouTubeUseCase
    let scheduleCacheStore: ScheduleCacheStoreProtocol
    let holidayStore: HolidayStoreProtocol
    let userScheduleMigrationStore: UserScheduleMigrationStoreProtocol

    // Compose dependencies from the live graph.
    init(
        qwerScheduleUseCase: QWERScheduleUseCase,
        userScheduleUseCase: UserScheduleUseCase,
        holidayUseCase: HolidayUseCase,
        youTubeUseCase: YouTubeUseCase,
        scheduleCacheStore: ScheduleCacheStoreProtocol,
        holidayStore: HolidayStoreProtocol,
        userScheduleMigrationStore: UserScheduleMigrationStoreProtocol
    ) {
        self.qwerScheduleUseCase = qwerScheduleUseCase
        self.userScheduleUseCase = userScheduleUseCase
        self.holidayUseCase = holidayUseCase
        self.youTubeUseCase = youTubeUseCase
        self.scheduleCacheStore = scheduleCacheStore
        self.holidayStore = holidayStore
        self.userScheduleMigrationStore = userScheduleMigrationStore
    }

    // Composition root with runtime-selectable remote strategy.
    static func configured(
        mode: RuntimeMode = .resolved(),
        userDefaults: UserDefaults = .standard
    ) -> AppEnvironment {
        AppEnvironmentFactory.make(mode: mode, userDefaults: userDefaults)
    }

    // Backward-compatible entry point.
    static func live(
        userDefaults: UserDefaults = .standard
    ) -> AppEnvironment {
        configured(mode: .live, userDefaults: userDefaults)
    }
}
