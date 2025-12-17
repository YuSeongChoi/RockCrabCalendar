//
//  QWERScheduleServiceTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2024/11/24.
//

import XCTest
@testable import RockCrabCalendar

final class QWERScheduleServiceTests: XCTestCase {
    private var suite: UserDefaults!
    private var service: QWERScheduleService!
    private let sampleDate = Date(timeIntervalSince1970: 0)
    
    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: "QWERScheduleServiceTests")
        suite.removePersistentDomain(forName: "QWERScheduleServiceTests")
        service = QWERScheduleService(userDefaults: suite)
    }
    
    override func tearDown() {
        suite.removePersistentDomain(forName: "QWERScheduleServiceTests")
        suite = nil
        service = nil
        super.tearDown()
    }
    
    private func makeSchedule(title: String = "테스트") -> QWERScheduleItem {
        QWERScheduleItem(
            title: title,
            date: sampleDate,
            time: "",
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            place: "서울",
            shouldNotify: false,
            members: [.Q],
            category: .other
        )
    }
    
    func testSaveLocalAndFetchLocalOnly() async {
        let item = makeSchedule()
        await service.saveLocalSchedule(item)
        
        let locals = await service.fetchLocalOnly()
        XCTAssertEqual(locals.count, 1)
        XCTAssertEqual(locals.first?.title, item.title)
    }
    
    func testUpdateLocalReplacesByID() async {
        var item = makeSchedule(title: "원본")
        await service.saveLocalSchedule(item)
        
        item.title = "수정됨"
        await service.updateLocalSchedule(item)
        
        let locals = await service.fetchLocalOnly()
        XCTAssertEqual(locals.first?.title, "수정됨")
    }
    
    func testDeleteLocalRemovesItem() async {
        let item = makeSchedule(title: "삭제 대상")
        await service.saveLocalSchedule(item)
        
        await service.deleteLocalSchedule(item)
        let locals = await service.fetchLocalOnly()
        XCTAssertTrue(locals.isEmpty)
    }
    
    func testIsLocalScheduleMatchesStored() async {
        let item = makeSchedule()
        await service.saveLocalSchedule(item)
        
        let isLocal = await service.isLocalSchedule(item)
        XCTAssertTrue(isLocal)
    }
}
