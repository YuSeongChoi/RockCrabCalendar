//
//  UserScheduleViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/30/25.
//

import Foundation

@Observable
final class UserScheduleViewModel {
    var schedules: [UserScheduleItem] = []
    
    private let service: UserScheduleService
    
    init(service: UserScheduleService = UserScheduleService()) {
        self.service = service
        self.schedules = service.schedules
    }
    
    func fetchAllSchedules() {
        Task {
            do {
                let fetched = try await service.fetchSchedule()
                schedules = fetched
            } catch {
                print("⚠️ 사용자 일정 fetch 실패:", error.localizedDescription)
            }
        }
    }
    
    func add(_ item: UserScheduleItem) {
        service.saveSchedule(item)
        schedules = service.schedules
        NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
    }
    
    func update(_ item: UserScheduleItem) {
        service.updateSchedule(item)
        schedules = service.schedules
        NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
    }
    
    func delete(_ item: UserScheduleItem) {
        service.deleteSchedule(item)
        schedules = service.schedules
        NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
    }
    
    func save(_ item: UserScheduleItem) {
        service.saveSchedule(item)
        schedules = service.schedules
        NotificationCenter.default.post(name: .userSchedulesDidChange, object: nil)
    }
}

