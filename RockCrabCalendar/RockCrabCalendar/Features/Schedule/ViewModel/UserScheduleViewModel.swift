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
        schedules = service.schedules.sorted(by: scheduleSortRule)
    }
    
    func update(_ item: UserScheduleItem) {
        service.updateSchedule(item)
        schedules = service.schedules.sorted(by: scheduleSortRule)
    }
    
    func delete(_ item: UserScheduleItem) {
        service.deleteSchedule(item)
        schedules = service.schedules.sorted(by: scheduleSortRule)
    }
    
    func save(_ item: UserScheduleItem) {
        service.saveSchedule(item)
        schedules = service.schedules.sorted(by: scheduleSortRule)
    }
    
    private func scheduleSortRule(_ a: UserScheduleItem, _ b: UserScheduleItem) -> Bool {
        let cal = Calendar.current
        if cal.isDate(a.date, inSameDayAs: b.date) {
            // time 문자열 비교 (비어 있으면 맨 뒤로)
            if a.time.isEmpty { return false }
            if b.time.isEmpty { return true }
            return (a.time as NSString).compare(b.time) == .orderedAscending
        } else {
            return a.date < b.date
        }
    }
}

