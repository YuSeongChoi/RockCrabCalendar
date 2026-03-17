import XCTest
@testable import RockCrabDomain

final class QWERScheduleItemStaticSchedulesTests: XCTestCase {
    func testStaticSchedulesAreSortedChronologically() {
        let schedules = QWERScheduleItem.schedules

        for (previous, current) in zip(schedules, schedules.dropFirst()) {
            XCTAssertLessThanOrEqual(
                previous.date,
                current.date,
                "정적 QWER 스케줄은 날짜 오름차순이어야 합니다: \(previous.title) -> \(current.title)"
            )
        }
    }

    func testStaticSchedulesDoNotContainDuplicateTitleDateAndPlace() {
        let formatter = QWERScheduleItem.simpleDateFormatter
        let keys = QWERScheduleItem.schedules.map {
            "\($0.title)|\(formatter.string(from: $0.date))|\($0.place)"
        }

        XCTAssertEqual(keys.count, Set(keys).count, "정적 QWER 스케줄에 중복 항목이 있으면 안 됩니다.")
    }
}
