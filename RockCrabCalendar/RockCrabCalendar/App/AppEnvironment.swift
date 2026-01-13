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
    let youTubeUseCase: YouTubeUseCase
    let holidayUseCase: HolidayUseCase

    // Live dependency graph for the app.
    init(
        qwerScheduleUseCase: QWERScheduleUseCase = QWERScheduleUseCase(repository: QWERScheduleService()),
        userScheduleUseCase: UserScheduleUseCase = UserScheduleUseCase(repository: UserScheduleService()),
        youTubeUseCase: YouTubeUseCase = YouTubeUseCase(repository: YouTubeRepositoryImpl()),
        holidayUseCase: HolidayUseCase = HolidayUseCase(repository: HolidayRepository())
    ) {
        self.qwerScheduleUseCase = qwerScheduleUseCase
        self.userScheduleUseCase = userScheduleUseCase
        self.youTubeUseCase = youTubeUseCase
        self.holidayUseCase = holidayUseCase
    }

    // Convenience for production usage.
    static let live = AppEnvironment()
}
