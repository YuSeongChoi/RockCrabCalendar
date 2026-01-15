//
//  CalendarViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import SwiftUI
import RockCrabShared
import RockCrabDomain

@Observable
final class CalendarViewModel {
    var currentMonth: Date = Date() {
        didSet { generateDays() }
    }
    var days: [Date] = []
    var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let holidayUseCase: HolidayUseCase
    private let holidayStore: HolidayStoreProtocol

    // Inject use-case for holiday sync.
    init(holidayUseCase: HolidayUseCase, holidayStore: HolidayStoreProtocol) {
        self.holidayUseCase = holidayUseCase
        self.holidayStore = holidayStore
        generateDays()
    }

    func generateDays() {
        days = CalendarGenerator.generateDaysInMonth(for: currentMonth, calendar: calendar)
    }

    func changeMonth(by offset: Int) {
        if let next = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = next
        }
    }

    func select(date: Date) {
        selectedDate = date
    }

    // 유틸 메서드
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    func startOfMonth(for date: Date) -> Date {
        return date.startOfMonth
    }

    func endOfMonth(for date: Date) -> Date {
        return date.endOfMonth
    }
    
    var numberOfWeeks: Int {
        return (days.count + 6) / 7
    }

    func cellHeight(for totalHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 240
        let adjustedHeight = max(totalHeight, minHeight)
        return adjustedHeight / CGFloat(numberOfWeeks)
    }

    func currentMonthRange() -> DateInterval {
        let start = startOfMonth(for: currentMonth)
        let end = endOfMonth(for: currentMonth)
        return DateInterval(start: start, end: end)
    }

    func holidayName(on date: Date) -> String? {
        holidayStore.name(on: date)
    }
}

extension CalendarViewModel {
    // Fetch holiday data once using the use-case boundary.
    func fetchHolidayOnce(baseYear: Int) async {
        do {
            if let items = try await holidayUseCase.fetchIfNeeded(baseYear: baseYear) {
                holidayStore.updateWithItems(items)
                print("✅ 공휴일 데이터 최초 API 호출 및 저장 완료")
            }
        } catch {
            print("❌ 공휴일 API 호출 실패:", error)
        }
    }
}
