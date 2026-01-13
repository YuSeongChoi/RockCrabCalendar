//
//  AppEnvironment.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Central DI container for assembling live dependencies.
final class AppEnvironment: ObservableObject {
    let qwerScheduleUseCase: QWERScheduleUseCase
    let userScheduleUseCase: UserScheduleUseCase
    let holidayUseCase: HolidayUseCase
    let youTubeRepository: YouTubeRepository

    // Compose dependencies from the live graph.
    init(
        qwerScheduleUseCase: QWERScheduleUseCase,
        userScheduleUseCase: UserScheduleUseCase,
        holidayUseCase: HolidayUseCase,
        youTubeRepository: YouTubeRepository
    ) {
        self.qwerScheduleUseCase = qwerScheduleUseCase
        self.userScheduleUseCase = userScheduleUseCase
        self.holidayUseCase = holidayUseCase
        self.youTubeRepository = youTubeRepository
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

        return AppEnvironment(
            qwerScheduleUseCase: qwerUseCase,
            userScheduleUseCase: userUseCase,
            holidayUseCase: holidayUseCase,
            youTubeRepository: youtubeRepository
        )
    }
}
