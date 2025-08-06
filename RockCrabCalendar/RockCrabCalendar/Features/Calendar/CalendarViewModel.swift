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
    var eventColorMap: [Date: Color] = [:]
    var swipeSelection: Int = 1

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
    func isSelected(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return calendar.isDate(d, inSameDayAs: selectedDate)
    }

    func isInCurrentMonth(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return calendar.isDate(d, equalTo: currentMonth, toGranularity: .month)
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
