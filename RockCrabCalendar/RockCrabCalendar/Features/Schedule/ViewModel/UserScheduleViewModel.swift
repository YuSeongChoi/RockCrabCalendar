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
        Task { @MainActor in
            do {
                let fetched = try await service.fetchSchedule()
                schedules = fetched
                await migrateLegacyTimesIfNeeded()
            } catch {
                print("⚠️ 사용자 일정 fetch 실패:", error.localizedDescription)
            }
        }
    }
    
    func add(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await service.saveSchedule(item)
                schedules = service.schedules.sorted(by: scheduleSortRule)
            } catch {
                print("⚠️ 사용자 일정 저장 실패:", error.localizedDescription)
            }
        }
    }
    
    func update(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await service.updateSchedule(item)
                schedules = service.schedules.sorted(by: scheduleSortRule)
            } catch {
                print("⚠️ 사용자 일정 업데이트 실패:", error.localizedDescription)
            }
        }
    }
    
    func delete(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await service.deleteSchedule(item)
                schedules = service.schedules.sorted(by: scheduleSortRule)
            } catch {
                print("⚠️ 사용자 일정 삭제 실패:", error.localizedDescription)
            }
        }
    }
    
    func save(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await service.saveSchedule(item)
                schedules = service.schedules.sorted(by: scheduleSortRule)
            } catch {
                print("⚠️ 사용자 일정 저장 실패:", error.localizedDescription)
            }
        }
    }
    
    private func scheduleSortRule(_ a: UserScheduleItem, _ b: UserScheduleItem) -> Bool {
        let cal = Calendar.current
        
        // 날짜 먼저 비교
        if !cal.isDate(a.date, inSameDayAs: b.date) {
            return a.date < b.date
        }
        
        // 같은 날짜일 경우: 하루종일 먼저
        if a.isAllDay != b.isAllDay {
            return a.isAllDay && !b.isAllDay
        }
        
        // 둘 다 하루종일이면 생성 순서 유지
        if a.isAllDay && b.isAllDay {
            return a.id.uuidString < b.id.uuidString
        }
        
        // 둘 다 시간 기반 일정일 경우: startTime 기준
        switch (a.startTime, b.startTime) {
        case (nil, nil):
            return a.id.uuidString < b.id.uuidString
        case (nil, _):
            return false
        case (_, nil):
            return true
        case (let sa?, let sb?):
            return sa < sb
        }
    }
}

// MARK: 로직 리뉴얼로 인해 migration
extension UserScheduleViewModel {
    func migrateLegacyTimesIfNeeded() async {
        // UserDefaults 등을 통해 한 번만 실행되도록 설정
        // TODO: 테스트용
        let key = "hasMigratedUserScheduleTimes"
        if UserDefaults.standard.bool(forKey: key) {
            return
        }
        var updatedItems: [UserScheduleItem] = []

        for item in schedules {
            // time만 있고 startTime이 없는 경우만 대상으로
            if !item.time.isEmpty && item.startTime == nil {
                var updated = item
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                formatter.locale = Locale(identifier: "ko_KR")
                if let parsed = formatter.date(from: item.time) {
                    updated.startTime = parsed
                    updated.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: parsed)
                    updated.isAllDay = false
                    updatedItems.append(updated)
                }
            }
        }

        // 저장 및 반영
        for updated in updatedItems {
            try? await service.updateSchedule(updated)
        }
        schedules = service.schedules.sorted(by: scheduleSortRule)

        UserDefaults.standard.set(true, forKey: key)
    }
}
