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

    // Live dependency graph for the app.
    init(
        qwerScheduleUseCase: QWERScheduleUseCase = QWERScheduleUseCase(repository: QWERScheduleService()),
        userScheduleUseCase: UserScheduleUseCase = UserScheduleUseCase(repository: UserScheduleService()),
        holidayUseCase: HolidayUseCase = HolidayUseCase(repository: HolidayRepository()),
        youTubeRepository: YouTubeRepository = YouTubeRepositoryImpl()
    ) {
        self.qwerScheduleUseCase = qwerScheduleUseCase
        self.userScheduleUseCase = userScheduleUseCase
        self.holidayUseCase = holidayUseCase
        self.youTubeRepository = youTubeRepository
    }

    // Convenience for production usage.
    static let live = AppEnvironment()
}
