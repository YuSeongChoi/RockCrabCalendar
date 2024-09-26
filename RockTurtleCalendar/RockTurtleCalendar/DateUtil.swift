//
//  DateUtil.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import UIKit

extension Date {
    func addWeek(n: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        return cal.date(byAdding: .weekOfMonth, value: n, to: self)!
    }
    
    func addyear(n: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        return cal.date(byAdding: .year, value: n, to: self)!
    }
    
    func addMonth(n: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        return cal.date(byAdding: .month, value: n, to: self)!
    }
    
    func addDay(n: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        return cal.date(byAdding: .day, value: n, to: self)!
    }
    
    func addTime(n: Int) -> Date {
        let cal = Calendar.autoupdatingCurrent
        return cal.date(byAdding: .second, value: n, to: self)!
    }
    
    func string(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.calendar = .init(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func int(format: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.calendar = .init(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return Int(dateFormatter.string(from: self)) ?? 0
    }
    
    // 해당 월의 총 일 수
    var daysInMonth: Int {
        let range = Calendar.current.range(of: .day, in: .month, for: self)
        return range?.count ?? 0
    }
    
    /// 현재 날짜의 주차
    var currentWeekDay: Int {
        return Calendar.current.ordinality(of: .weekOfMonth, in: .month, for: self) ?? 1
    }
    
    /// 현재 날짜의 일
    var currentDay: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 현재 날짜의 요일번호 1.  일요일 ~ 7 = 토요일
    var currentDayNum: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    var startDay: Date {
        return self.dateChange(day: 1)
    }
    
    var endDay: Date {
        let dayRange = Calendar.current.range(of: .day, in: .month, for: self)
        return self.dateChange(day: dayRange?.last ?? 30)
    }
    
    func dateChange(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil) -> Date {
        let dateComponents = DateComponents(
            year: year == nil ? self.int(format: "yyyy") : year,
            month: month == nil ? self.int(format: "MM") : month,
            day: day == nil ? self.int(format: "dd") : daysInMonth,
            hour: hour,
            minute: minute
        )
        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    var removeTime: Date {
        let dateComponents = DateComponents(
            year: self.int(format: "yyyy"),
            month: self.int(format: "MM"),
            day: self.int(format: "dd"),
            hour: 0,
            minute: 0,
            second: 0
        )
        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    static func date(_ target: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.calendar = .init(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: target)
    }
    
}


