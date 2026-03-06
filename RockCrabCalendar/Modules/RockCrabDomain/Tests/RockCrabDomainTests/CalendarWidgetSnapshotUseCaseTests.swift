import XCTest
@testable import RockCrabDomain

final class CalendarWidgetSnapshotUseCaseTests: XCTestCase {
    private let useCase = CalendarWidgetSnapshotUseCase()

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.firstWeekday = 2 // Monday
        return cal
    }

    func testTodaySnapshotContainsOnlyTodaySchedules() {
        let baseDate = date(2026, 3, 6, 12, 0)
        let qwer = [
            qwerItem(title: "오늘 QWER", date: date(2026, 3, 6, 9, 0)),
            qwerItem(title: "내일 QWER", date: date(2026, 3, 7, 9, 0))
        ]
        let user = [
            userItem(title: "오늘 개인", date: date(2026, 3, 6, 10, 0)),
            userItem(title: "어제 개인", date: date(2026, 3, 5, 10, 0))
        ]

        let result = useCase.makeSnapshot(
            period: .today,
            baseDate: baseDate,
            qwerSchedules: qwer,
            userSchedules: user,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.title), ["오늘 QWER", "오늘 개인"])
    }

    func testWeekSnapshotExpandsWeeklyRepeat() {
        let baseDate = date(2026, 3, 6, 12, 0) // Friday
        let weekly = userItem(
            title: "주간 반복",
            date: date(2026, 2, 20, 10, 0),
            isRepeat: true,
            repeatType: .week,
            repeatEndDate: date(2026, 3, 30, 0, 0)
        )

        let result = useCase.makeSnapshot(
            period: .week,
            baseDate: baseDate,
            qwerSchedules: [],
            userSchedules: [weekly],
            calendar: calendar
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "주간 반복")
        XCTAssertEqual(result.first?.date, date(2026, 3, 6, 10, 0))
    }

    func testMonthSnapshotSortsAllDayFirstThenTime() {
        let baseDate = date(2026, 3, 6, 12, 0)
        let sameDayAllDay = userItem(
            title: "종일",
            date: date(2026, 3, 10, 0, 0),
            isAllDay: true,
            startTime: nil,
            endTime: nil
        )
        let sameDayTimed = userItem(
            title: "시간",
            date: date(2026, 3, 10, 0, 0),
            isAllDay: false,
            startTime: date(2026, 3, 10, 11, 0),
            endTime: date(2026, 3, 10, 12, 0)
        )

        let result = useCase.makeSnapshot(
            period: .month,
            baseDate: baseDate,
            qwerSchedules: [],
            userSchedules: [sameDayTimed, sameDayAllDay],
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.title), ["종일", "시간"])
    }
}

private extension CalendarWidgetSnapshotUseCaseTests {
    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        return calendar.date(from: comps)!
    }

    func qwerItem(title: String, date: Date) -> QWERScheduleItem {
        QWERScheduleItem(
            title: title,
            date: date,
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

    func userItem(
        title: String,
        date: Date,
        isAllDay: Bool = true,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isRepeat: Bool = false,
        repeatType: UserScheduleItem.RepeatType? = nil,
        repeatEndDate: Date? = nil
    ) -> UserScheduleItem {
        UserScheduleItem(
            title: title,
            date: date,
            time: "",
            isAllDay: isAllDay,
            startTime: startTime,
            endTime: endTime,
            place: "서울",
            shouldNotify: false,
            isRepeat: isRepeat,
            repeatType: repeatType,
            repeatEndDate: repeatEndDate
        )
    }
}
