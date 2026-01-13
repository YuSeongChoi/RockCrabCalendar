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

    private let useCase: UserScheduleUseCase

    // Inject use-case for DI and testability.
    init(useCase: UserScheduleUseCase = UserScheduleUseCase(repository: UserScheduleService())) {
        self.useCase = useCase
        self.schedules = []
    }
    
    // Fetch schedules via use-case and apply ordering.
    func fetchAllSchedules() {
        Task { @MainActor in
            do {
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
                await migrateLegacyTimesIfNeeded()
            } catch {
                AppLogger.error("사용자 일정 fetch 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // Add schedule via use-case and refresh list.
    func add(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await useCase.add(item)
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
            } catch {
                AppLogger.error("사용자 일정 저장 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // Update schedule via use-case and refresh list.
    func update(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await useCase.update(item)
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
            } catch {
                AppLogger.error("사용자 일정 업데이트 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // Delete schedule via use-case and refresh list.
    func delete(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await useCase.delete(item)
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
            } catch {
                AppLogger.error("사용자 일정 삭제 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // Save (alias of add) via use-case and refresh list.
    func save(_ item: UserScheduleItem) {
        Task { @MainActor in
            do {
                try await useCase.add(item)
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
            } catch {
                AppLogger.error("사용자 일정 저장 실패: \(error.localizedDescription)", category: .scheduleVM)
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
    // One-time migration for legacy time fields.
    func migrateLegacyTimesIfNeeded() async {
        // UserDefaults 등을 통해 한 번만 실행되도록 설정
        // TODO: 테스트용
        let key = AppStorageKeys.userScheduleLegacyTimeMigration
        if UserDefaults.standard.bool(forKey: key) {
            return
        }
        var updatedItems: [UserScheduleItem] = []

        for item in schedules {
            // time만 있고 startTime이 없는 경우만 대상으로
            if !item.time.isEmpty && item.startTime == nil {
                var updated = item
                let formatter = DateFormatter()
                formatter.dateFormat = AppDateFormats.hourMinute
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
            try? await useCase.update(updated)
        }
        if let refreshed = try? await useCase.fetchAll() {
            schedules = refreshed.sorted(by: scheduleSortRule)
        }

        UserDefaults.standard.set(true, forKey: key)
    }
}
