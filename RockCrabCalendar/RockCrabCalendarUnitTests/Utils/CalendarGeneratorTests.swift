//
//  CalendarGeneratorTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2024/11/24.
//

import XCTest
@testable import RockCrabCalendar

final class CalendarGeneratorTests: XCTestCase {
    private var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }
    
    func testMarch2024HasSixWeeksGrid() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        let days = CalendarGenerator.generateDaysInMonth(for: date, calendar: calendar)
        
        XCTAssertEqual(days.count, 42) // 6주 * 7일
        XCTAssertEqual(calendar.component(.weekday, from: days.first!), 1) // Sunday start
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2024, month: 2, day: 25))!, days.first)
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2024, month: 4, day: 6))!, days.last)
    }
    
    func testApril2024HasFiveWeeksGrid() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 4, day: 1))!
        let days = CalendarGenerator.generateDaysInMonth(for: date, calendar: calendar)
        
        XCTAssertEqual(days.count, 35) // 5주 * 7일
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2024, month: 3, day: 31))!, days.first)
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2024, month: 5, day: 4))!, days.last)
    }
}
