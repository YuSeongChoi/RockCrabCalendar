import Foundation

public enum CalendarWidgetPeriod {
    case today
    case week
    case month
}

public struct CalendarWidgetScheduleSummary: Equatable {
    public enum Source: Equatable {
        case qwer
        case user
    }

    public let title: String
    public let date: Date
    public let isAllDay: Bool
    public let startTime: Date?
    public let endTime: Date?
    public let place: String
    public let source: Source
    public let members: [QWERMember]
    public let userColorHex: String?

    public init(
        title: String,
        date: Date,
        isAllDay: Bool,
        startTime: Date?,
        endTime: Date?,
        place: String,
        source: Source,
        members: [QWERMember] = [],
        userColorHex: String? = nil
    ) {
        self.title = title
        self.date = date
        self.isAllDay = isAllDay
        self.startTime = startTime
        self.endTime = endTime
        self.place = place
        self.source = source
        self.members = members
        self.userColorHex = userColorHex
    }
}

public struct CalendarWidgetSnapshotUseCase {
    public init() {}

    public func makeSnapshot(
        period: CalendarWidgetPeriod,
        baseDate: Date,
        qwerSchedules: [QWERScheduleItem],
        userSchedules: [UserScheduleItem],
        calendar: Calendar = .current
    ) -> [CalendarWidgetScheduleSummary] {
        let interval = range(for: period, baseDate: baseDate, calendar: calendar)
        let qwer = qwerSchedules
            .filter { interval.contains($0.date) }
            .map {
                CalendarWidgetScheduleSummary(
                    title: $0.title,
                    date: $0.date,
                    isAllDay: $0.isAllDay,
                    startTime: $0.startTime,
                    endTime: $0.endTime,
                    place: $0.place,
                    source: .qwer,
                    members: $0.members
                )
            }

        let user = expandUserSchedules(userSchedules, in: interval, calendar: calendar)

        return (qwer + user).sorted(by: sortRule)
    }

    private func range(for period: CalendarWidgetPeriod, baseDate: Date, calendar: Calendar) -> DateInterval {
        let dayStart = calendar.startOfDay(for: baseDate)
        switch period {
        case .today:
            let end = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            return DateInterval(start: dayStart, end: end)
        case .week:
            let weekday = calendar.component(.weekday, from: dayStart)
            let offset = (weekday - calendar.firstWeekday + 7) % 7
            let weekStart = calendar.date(byAdding: .day, value: -offset, to: dayStart) ?? dayStart
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            return DateInterval(start: weekStart, end: weekEnd)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: dayStart)
            let monthStart = calendar.date(from: comps) ?? dayStart
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            return DateInterval(start: monthStart, end: monthEnd)
        }
    }

    private func expandUserSchedules(
        _ userSchedules: [UserScheduleItem],
        in interval: DateInterval,
        calendar: Calendar
    ) -> [CalendarWidgetScheduleSummary] {
        var result: [CalendarWidgetScheduleSummary] = []
        for item in userSchedules {
            result.append(contentsOf: occurrences(for: item, in: interval, calendar: calendar))
        }
        return result
    }

    private func occurrences(
        for item: UserScheduleItem,
        in interval: DateInterval,
        calendar: Calendar
    ) -> [CalendarWidgetScheduleSummary] {
        let startDay = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: interval.end)
        let itemDay = calendar.startOfDay(for: item.date)

        let repeatType: UserScheduleItem.RepeatType = item.repeatType ?? .none
        if !item.isRepeat || repeatType == .none {
            guard itemDay >= startDay && itemDay < endDay else { return [] }
            return [summary(from: item, date: item.date, calendar: calendar)]
        }

        var dates: [Date] = []
        var current = itemDay
        let repeatEnd = min(
            endDay,
            calendar.startOfDay(for: item.repeatEndDate ?? endDay)
        )

        while current < startDay {
            guard let next = nextDate(from: current, type: item.repeatType ?? .none, calendar: calendar) else {
                break
            }
            current = next
        }

        while current < repeatEnd {
            if current >= startDay {
                dates.append(current)
            }
            guard let next = nextDate(from: current, type: repeatType, calendar: calendar) else {
                break
            }
            current = next
        }

        return dates.map { summary(from: item, date: $0, calendar: calendar) }
    }

    private func nextDate(
        from date: Date,
        type: UserScheduleItem.RepeatType,
        calendar: Calendar
    ) -> Date? {
        switch type {
        case .none:
            return nil
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .week:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .year:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func summary(
        from item: UserScheduleItem,
        date: Date,
        calendar: Calendar
    ) -> CalendarWidgetScheduleSummary {
        let resolvedDate = resolvedOccurrenceDate(for: item, day: date, calendar: calendar)
        return CalendarWidgetScheduleSummary(
            title: item.title,
            date: resolvedDate,
            isAllDay: item.isAllDay,
            startTime: item.startTime,
            endTime: item.endTime,
            place: item.place,
            source: .user,
            userColorHex: item.colorHex
        )
    }

    private func resolvedOccurrenceDate(
        for item: UserScheduleItem,
        day: Date,
        calendar: Calendar
    ) -> Date {
        guard item.isRepeat else { return day }

        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        if let startTime = item.startTime {
            let time = calendar.dateComponents([.hour, .minute, .second], from: startTime)
            comps.hour = time.hour
            comps.minute = time.minute
            comps.second = time.second
            return calendar.date(from: comps) ?? day
        }

        let source = calendar.dateComponents([.hour, .minute, .second], from: item.date)
        comps.hour = source.hour
        comps.minute = source.minute
        comps.second = source.second
        return calendar.date(from: comps) ?? day
    }

    private func sortRule(_ lhs: CalendarWidgetScheduleSummary, _ rhs: CalendarWidgetScheduleSummary) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        if lhs.isAllDay != rhs.isAllDay {
            return lhs.isAllDay && !rhs.isAllDay
        }
        switch (lhs.startTime, rhs.startTime) {
        case (nil, nil):
            if lhs.source != rhs.source {
                return lhs.source == .qwer
            }
            return lhs.title < rhs.title
        case (nil, _):
            return false
        case (_, nil):
            return true
        case (let l?, let r?):
            return l < r
        }
    }
}
