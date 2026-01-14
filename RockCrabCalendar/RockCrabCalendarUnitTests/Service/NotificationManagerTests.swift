//
//  NotificationManagerTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2024/11/24.
//

import XCTest
@testable import RockCrabCalendar
import RockCrabDomain

final class NotificationManagerTests: XCTestCase {
    private let manager = NotificationManager.shared
    
    struct DummySchedule: SchedulableItemProtocol, Codable {
        var id: UUID
        var title: String
        var date: Date
        var time: String
        var isAllDay: Bool
        var startTime: Date?
        var endTime: Date?
        var place: String
        var shouldNotify: Bool
        
        init(
            id: UUID,
            title: String,
            date: Date,
            time: String,
            isAllDay: Bool,
            startTime: Date?,
            endTime: Date?,
            place: String,
            shouldNotify: Bool
        ) {
            self.id = id
            self.title = title
            self.date = date
            self.time = time
            self.isAllDay = isAllDay
            self.startTime = startTime
            self.endTime = endTime
            self.place = place
            self.shouldNotify = shouldNotify
        }
    }
    
    func testNotificationIDComposition() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let result = manager.notificationID(for: id, offset: 300)
        XCTAssertEqual(result, "\(id.uuidString)-300")
    }
    
    func testBuildStartDateAllDayUsesStartOfDay() {
        let date = Date(timeIntervalSince1970: 60 * 60 * 24) // 1970-01-02 00:00:00 UTC
        let schedule = DummySchedule(
            id: UUID(),
            title: "allDay",
            date: date,
            time: "",
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            place: "",
            shouldNotify: true
        )
        
        let result = manager.buildStartDate(from: schedule)
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute, .second], from: result!)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
    }
    
    func testBuildStartDateUsesStartTimeWhenPresent() {
        var dateComps = DateComponents()
        dateComps.year = 2024
        dateComps.month = 6
        dateComps.day = 1
        dateComps.hour = 10
        dateComps.minute = 30
        let startTime = Calendar.current.date(from: dateComps)!
        
        let schedule = DummySchedule(
            id: UUID(),
            title: "timed",
            date: startTime,
            time: "",
            isAllDay: false,
            startTime: startTime,
            endTime: nil,
            place: "",
            shouldNotify: true
        )
        
        let result = manager.buildStartDate(from: schedule)
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: result!)
        XCTAssertEqual(comps.hour, 10)
        XCTAssertEqual(comps.minute, 30)
    }
}
