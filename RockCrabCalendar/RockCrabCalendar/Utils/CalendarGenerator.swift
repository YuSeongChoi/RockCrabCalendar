//
//  CalendarGenerator.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation

struct CalendarGenerator {
    static func generateDaysInMonth(
        for date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth)!
            .addingTimeInterval(-1)

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.component(.day, from: lastDayOfMonth)

        let totalNeeded = (firstWeekday - 1) + daysInMonth
        let weeks = (totalNeeded <= 35) ? 5 : 6

        let startDate = calendar.date(
            byAdding: .day,
            value: -(firstWeekday - 1),
            to: firstDayOfMonth
        )!

        return (0..<(weeks*7)).map {
            calendar.date(byAdding: .day, value: $0, to: startDate)!
        }
    }
}
