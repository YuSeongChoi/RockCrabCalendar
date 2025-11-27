//
//  CalendarViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import SwiftUI
import Combine

@Observable
final class CalendarViewModel {
    var currentMonth: Date = Date() {
        didSet { generateDays() }
    }
    var days: [Date] = []
    var selectedDate: Date = Date()

    private let calendar = Calendar.current

    init() {
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
}
