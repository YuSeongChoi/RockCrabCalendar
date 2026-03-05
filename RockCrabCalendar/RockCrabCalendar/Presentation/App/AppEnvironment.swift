//
//  AppEnvironment.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/09.
//

import Foundation
import RockCrabDomain
import RockCrabData

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
        let qwerRemote: QWERScheduleRemoteDataSource
        switch mode {
        case .live:
            qwerRemote = FirestoreQWERScheduleRemoteDataSource()
        case .localOnly, .mock:
            qwerRemote = NoopQWERScheduleRemoteDataSource()
        }
        return compose(qwerRemote: qwerRemote, userDefaults: userDefaults)
    }

    // Backward-compatible entry point.
    static func live(
        userDefaults: UserDefaults = .standard
    ) -> AppEnvironment {
        configured(mode: .live, userDefaults: userDefaults)
    }

    private static func compose(
        qwerRemote: QWERScheduleRemoteDataSource,
        userDefaults: UserDefaults
    ) -> AppEnvironment {
        // DataSources
        let qwerLocal = UserDefaultsQWERScheduleLocalDataSource(userDefaults: userDefaults)
        let userLocal = UserDefaultsUserScheduleLocalDataSource(userDefaults: userDefaults)
        let holidayRemote = HolidayAPIRemoteDataSource()
        let holidayCache = HolidayCacheStoreDataSource()
        let youtubeRemote = YouTubeAPIRemoteDataSource()

        // Repositories
        let qwerRepository = QWERScheduleService(remote: qwerRemote, local: qwerLocal)
        let userRepository = UserScheduleService(local: userLocal)
        let holidayRepository = HolidayRepository(cacheStore: holidayCache, remote: holidayRemote)
        let youtubeRepository = YouTubeRepositoryImpl(remote: youtubeRemote)

        // UseCases
        let qwerUseCase = QWERScheduleUseCase(repository: qwerRepository)
        let userUseCase = UserScheduleUseCase(repository: userRepository)
        let holidayUseCase = HolidayUseCase(repository: holidayRepository)
        let youtubeUseCase = YouTubeUseCase(repository: youtubeRepository)
        let scheduleCacheStore = ScheduleCacheStore(userDefaults: userDefaults)
        let holidayStore = HolidayStore(userDefaults: userDefaults)
        let userScheduleMigrationStore = UserScheduleMigrationStore(userDefaults: userDefaults)

        return AppEnvironment(
            qwerScheduleUseCase: qwerUseCase,
            userScheduleUseCase: userUseCase,
            holidayUseCase: holidayUseCase,
            youTubeUseCase: youtubeUseCase,
            scheduleCacheStore: scheduleCacheStore,
            holidayStore: holidayStore,
            userScheduleMigrationStore: userScheduleMigrationStore
        )
    }
}
