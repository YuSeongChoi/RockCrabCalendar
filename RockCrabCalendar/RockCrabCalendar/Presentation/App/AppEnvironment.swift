//
//  AppEnvironment.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabDomain
import RockCrabData

// Central DI container for assembling live dependencies.
final class AppEnvironment: ObservableObject {
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

    // Live composition root (single place to wire concrete implementations).
    static func live(
        userDefaults: UserDefaults = .standard
    ) -> AppEnvironment {
        // DataSources
        let qwerRemote = FirestoreQWERScheduleRemoteDataSource()
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
