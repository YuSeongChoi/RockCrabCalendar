//
//  AppEnvironmentFactory.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/03/05.
//

import Foundation
import RockCrabData
import RockCrabDataFirestore
import RockCrabDomain

enum AppEnvironmentFactory {
    static func make(
        mode: AppEnvironment.RuntimeMode,
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

    private static func compose(
        qwerRemote: QWERScheduleRemoteDataSource,
        userDefaults: UserDefaults
    ) -> AppEnvironment {
        let qwerLocal = UserDefaultsQWERScheduleLocalDataSource(userDefaults: userDefaults)
        let userLocal = UserDefaultsUserScheduleLocalDataSource(userDefaults: userDefaults)
        let holidayRemote = HolidayAPIRemoteDataSource()
        let holidayCache = HolidayCacheStoreDataSource()
        let youtubeRemote = YouTubeAPIRemoteDataSource()

        let qwerRepository = QWERScheduleService(remote: qwerRemote, local: qwerLocal)
        let userRepository = UserScheduleService(local: userLocal)
        let holidayRepository = HolidayRepository(cacheStore: holidayCache, remote: holidayRemote)
        let youtubeRepository = YouTubeRepositoryImpl(remote: youtubeRemote)

        let qwerUseCase = QWERScheduleUseCase(repository: qwerRepository)
        let userUseCase = UserScheduleUseCase(repository: userRepository)
        let holidayUseCase = HolidayUseCase(repository: holidayRepository)
        let youtubeUseCase = YouTubeUseCase(repository: youtubeRepository)
        let scheduleCacheStore = ScheduleCacheStore(userDefaults: userDefaults)
        let holidayStore = HolidayStore(userDefaults: userDefaults)
        let userScheduleMigrationStore = UserScheduleMigrationStore(userDefaults: userDefaults)
        let scheduleRecordStore = UserDefaultsScheduleRecordStore(userDefaults: userDefaults)

        return AppEnvironment(
            qwerScheduleUseCase: qwerUseCase,
            userScheduleUseCase: userUseCase,
            holidayUseCase: holidayUseCase,
            youTubeUseCase: youtubeUseCase,
            scheduleCacheStore: scheduleCacheStore,
            holidayStore: holidayStore,
            userScheduleMigrationStore: userScheduleMigrationStore,
            scheduleRecordStore: scheduleRecordStore
        )
    }
}
