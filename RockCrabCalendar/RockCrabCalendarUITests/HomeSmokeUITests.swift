//
//  HomeSmokeUITests.swift
//  RockCrabCalendarUITests
//
//  Created by Codex on 2024/11/24.
//

import XCTest

final class HomeSmokeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenLoadsAndControlsExist() throws {
        let app = XCUIApplication()
        app.launch()

        // 기본 네비게이션 타이틀/버튼 존재 확인
        XCTAssertTrue(app.navigationBars.buttons["필터"].exists || app.buttons["필터"].exists)
        XCTAssertTrue(app.buttons["오늘"].exists)

        // 캘린더/리스트 토글이 존재하는지 확인
        XCTAssertTrue(app.buttons.matching(identifier: "list.bullet").firstMatch.exists
                      || app.buttons.matching(identifier: "calendar").firstMatch.exists)

        // 플로팅 버튼(+) 존재 확인
        XCTAssertTrue(app.buttons.matching(identifier: "plus").firstMatch.exists)
    }
}
