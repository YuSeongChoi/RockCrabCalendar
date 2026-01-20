//
//  UserScheduleViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/30/25.
//

import Foundation
import RockCrabShared
import RockCrabDomain

@Observable
final class UserScheduleViewModel {
    var schedules: [UserScheduleItem] = []

    private let useCase: UserScheduleUseCase
    private let migrationStore: UserScheduleMigrationStoreProtocol

    // Inject use-case for DI and testability.
    init(useCase: UserScheduleUseCase, migrationStore: UserScheduleMigrationStoreProtocol) {
        self.useCase = useCase
        self.migrationStore = migrationStore
        self.schedules = []
    }
    
    // Fetch schedules via use-case and apply ordering.
    func fetchAllSchedules() {
        Task { @MainActor in
            do {
                let fetched = try await useCase.fetchAll()
                schedules = fetched.sorted(by: scheduleSortRule)
                let didMigrate = try await useCase.migrateLegacyTimesIfNeeded(migrationStore: migrationStore)
                if didMigrate {
                    let refreshed = try await useCase.fetchAll()
                    schedules = refreshed.sorted(by: scheduleSortRule)
                }
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

// MARK: - Query helpers
extension UserScheduleViewModel {
    func latestSchedule(for item: UserScheduleItem) -> UserScheduleItem {
        schedules.first(where: { $0.id == item.id }) ?? item
    }

    func schedules(on date: Date) -> [UserScheduleItem] {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let interval = DateInterval(start: day, end: day)
        return schedules(in: interval)
    }

    func schedules(in range: DateInterval) -> [UserScheduleItem] {
        let cal = Calendar.current
        let rangeStart = cal.startOfDay(for: range.start)
        let rangeEnd = cal.startOfDay(for: range.end)
        var result: [UserScheduleItem] = []

        for item in schedules {
            result.append(contentsOf: generateOccurrences(for: item, rangeStart: rangeStart, rangeEnd: rangeEnd, calendar: cal))
        }

        return result.sorted { $0.date < $1.date }
    }

    private func generateOccurrences(
        for item: UserScheduleItem,
        rangeStart: Date,
        rangeEnd: Date,
        calendar cal: Calendar
    ) -> [UserScheduleItem] {
        // Non-repeating: include only if inside range
        if !item.isRepeat || item.repeatType == .none {
            let d = cal.startOfDay(for: item.date)
            guard d >= rangeStart && d <= rangeEnd else { return [] }
            return [UserScheduleItem(
                id: item.id,
                title: item.title,
                date: d,
                time: item.time,
                isAllDay: item.isAllDay,
                startTime: item.startTime,
                endTime: item.endTime,
                place: item.place,
                shouldNotify: item.shouldNotify,
                isRepeat: item.isRepeat,
                repeatType: item.repeatType,
                repeatEndDate: item.repeatEndDate,
                colorHex: item.colorHex
            )]
        }

        // Repeating: iterate occurrences
        var occurrences: [UserScheduleItem] = []
        var current = cal.startOfDay(for: item.date)
        let effectiveEnd = min(rangeEnd, cal.startOfDay(for: item.repeatEndDate ?? rangeEnd))

        // Fast-forward to the first occurrence on/after rangeStart
        switch item.repeatType ?? .none {
        case .week:
            if current < rangeStart {
                if let days = cal.dateComponents([.day], from: current, to: rangeStart).day {
                    let remainder = days % 7
                    let advance = remainder == 0 ? 0 : (7 - remainder)
                    current = cal.date(byAdding: .day, value: days + advance, to: current) ?? current
                }
            }
        case .day, .month, .year, .none:
            while current < rangeStart {
                guard let next = nextOccurrenceDate(from: current, type: item.repeatType ?? .none, calendar: cal) else { break }
                current = next
            }
        }

        while current <= effectiveEnd {
            if current >= rangeStart {
                occurrences.append(UserScheduleItem(
                    id: item.id,
                    title: item.title,
                    date: current,
                    time: item.time,
                    isAllDay: item.isAllDay,
                    startTime: item.startTime,
                    endTime: item.endTime,
                    place: item.place,
                    shouldNotify: item.shouldNotify,
                    isRepeat: item.isRepeat,
                    repeatType: item.repeatType,
                    repeatEndDate: item.repeatEndDate,
                    colorHex: item.colorHex
                ))
            }
            guard let next = nextOccurrenceDate(from: current, type: item.repeatType ?? .none, calendar: cal) else { break }
            current = next
        }

        return occurrences
    }

    private func nextOccurrenceDate(from date: Date, type: UserScheduleItem.RepeatType, calendar cal: Calendar) -> Date? {
        switch type {
        case .none:
            return nil
        case .day:
            return cal.date(byAdding: .day, value: 1, to: date)
        case .week:
            return cal.date(byAdding: .day, value: 7, to: date)
        case .month:
            return cal.date(byAdding: .month, value: 1, to: date)
        case .year:
            return cal.date(byAdding: .year, value: 1, to: date)
        }
    }
}
