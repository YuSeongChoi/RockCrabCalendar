//
//  CalendarManager.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import Foundation

class CalendarManager: ObservableObject {
    @Published var currentDate: Date
    
    init() {
        // 현재 날짜로 초기화
        self.currentDate = Date()
    }
    
    /// 특정 해당 날짜
    func getDate(for index: Int) -> Date {
        let calendar = Calendar.current
        guard let firstDayOfMonth = calendar.date(
            from: DateComponents(
                year: calendar.component(.year, from: currentDate),
                month: calendar.component(.month, from: currentDate),
                day: 1
            )
        ) else {
            return Date()
        }
        var dateComponents = DateComponents()
        dateComponents.day = index
        
        let timeZone = TimeZone.current
        let offset = Double(timeZone.secondsFromGMT(for: firstDayOfMonth))
        dateComponents.second = Int(offset)
        
        let date = calendar.date(byAdding: dateComponents, to: firstDayOfMonth) ?? Date()
        return date
    }
    
    /// 해당 월에 존재하는 일자 수
    func numberOfDays(in date: Date) -> Int {
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    /// 해당 월의 첫 날짜가 갖는 해당 주의 몇번째 요일
    func firstWeekdayOfmOnth(in date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: firstDayOfMonth)
    }
    
    /// 이전 월 마지막 일자
    func previousMonth() -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: currentDate)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        return previousMonth
    }
    
    /// 월 변경
    func changeMonth(by value: Int) {
        self.currentDate = adjustedMonth(by: value)
    }
    
    /// 변경하려는 월 변환
    func adjustedMonth(by value: Int) -> Date {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            return newMonth
        }
        return currentDate
    }
}

extension Date {
    static let calendarDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy dd"
        return formatter
    }()
    
    static let calendarHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    
    static let weekdaySymbols: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    
    var formattedCalendarDayDate: String {
        return Date.calendarDayDateFormatter.string(from: self)
    }
}
