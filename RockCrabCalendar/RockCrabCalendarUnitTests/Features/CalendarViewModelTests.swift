//
//  CalendarViewModelTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2024/11/24.
//

import XCTest
@testable import RockCrabCalendar

final class CalendarViewModelTests: XCTestCase {
    func testChangeMonthUpdatesCurrentMonth() {
        let vm = CalendarViewModel()
        let initial = vm.currentMonth
        vm.changeMonth(by: 1)
        XCTAssertNotEqual(vm.currentMonth, initial)
    }
    
    func testNumberOfWeeksMatchesGeneratedDays() {
        let vm = CalendarViewModel()
        vm.currentMonth = Date(timeIntervalSince1970: 0) // 1970-01
        let expectedWeeks = (vm.days.count + 6) / 7
        XCTAssertEqual(vm.numberOfWeeks, expectedWeeks)
    }
    
    func testCellHeightRespectsMinimum() {
        let vm = CalendarViewModel()
        vm.currentMonth = Date()
        let height = vm.cellHeight(for: 100)
        XCTAssertGreaterThanOrEqual(height * CGFloat(vm.numberOfWeeks), 240)
    }
}
