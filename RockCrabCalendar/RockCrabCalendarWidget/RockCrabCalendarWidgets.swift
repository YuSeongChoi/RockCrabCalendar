import SwiftUI
import WidgetKit
import RockCrabDomain
import RockCrabShared

private struct WidgetRootView: View {
    var entry: RockCrabCalendarWidgetEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = AppLocalization.locale
        cal.timeZone = .current
        cal.firstWeekday = 1
        return cal
    }()
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = AppLocalization.locale
        formatter.timeZone = .autoupdatingCurrent
        return formatter.veryShortStandaloneWeekdaySymbols
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        case .systemMedium:
            weekCalendarBody
        default:
            monthCalendarBody
        }
    }

    private var smallBody: some View {
        let todayItems = entry.items
            .filter { calendar.isDate($0.date, inSameDayAs: entry.date) }
            .sorted(by: smallSortRule)
        let visibleItems = Array(todayItems.prefix(4))
        let hiddenCount = max(0, todayItems.count - visibleItems.count)

        return VStack(alignment: .leading, spacing: 3) {
            Text(AppLocalization.localized(ko: "오늘", en: "Today"))
                .font(.headline)

            if visibleItems.isEmpty {
                Text(AppLocalization.localized(ko: "일정 없음", en: "No schedules"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(Array(visibleItems.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 4) {
                        Text(timeText(for: item))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(width: 54, alignment: .leading)
                        Text(item.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if hiddenCount > 0 {
                    HStack {
                        Spacer()
                        Text(AppLocalization.prefersEnglish ? "\(hiddenCount) more" : "외 \(hiddenCount)개 일정")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(todayItems.first.map(deepLinkURL(for:)))
    }

    private var weekCalendarBody: some View {
        let weekDates = weekDays(for: entry.date)
        return GeometryReader { proxy in
            let headerHeight: CGFloat = 26
            let weekdayHeight: CGFloat = 11
            let verticalSpacing: CGFloat = 5
            let rowMinHeight: CGFloat = 42
            let available = proxy.size.height - headerHeight - weekdayHeight - (verticalSpacing * 2)
            let cellHeight = max(rowMinHeight, min(58, available))

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(AppLocalization.localized(ko: "이번 주", en: "This Week"))
                    .font(.headline)
                    .frame(height: headerHeight, alignment: .topLeading)
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: weekdayHeight, alignment: .top)

                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { day in
                        Link(destination: deepLinkURL(for: day)) {
                            VStack(spacing: 2) {
                                dayNumberView(for: day, font: .caption, circleSize: 20)
                                Text(holidayName(on: day) ?? " ")
                                    .font(.system(size: 7, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundStyle(.red)
                                    .frame(height: 9)
                                DayEventDots(colors: dayEventColors(on: day), isDark: colorScheme == .dark, maxCount: 3)
                            }
                            .frame(maxWidth: .infinity, minHeight: cellHeight, alignment: .top)
                        }
                    }
                }
                .frame(minHeight: cellHeight, maxHeight: cellHeight, alignment: .top)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var monthCalendarBody: some View {
        let monthDays = monthGridDays(for: entry.date)
        let rowCount = max(1, monthDays.count / 7)

        return GeometryReader { proxy in
            let headerHeight: CGFloat = 34
            let weekdayHeight: CGFloat = 12
            let verticalSpacing: CGFloat = 4
            let gridTopPadding: CGFloat = 2
            let available = proxy.size.height - headerHeight - weekdayHeight - gridTopPadding - verticalSpacing
            let cellHeight = max(24, available / CGFloat(rowCount))

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(monthTitle(entry.date))
                    .font(.headline)
                    .frame(height: headerHeight, alignment: .topLeading)
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: weekdayHeight, alignment: .top)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                        if let day {
                            Link(destination: deepLinkURL(for: day)) {
                                VStack(spacing: 2) {
                                    dayNumberView(for: day, font: .caption2, circleSize: 16)
                                    Text(holidayName(on: day) ?? " ")
                                        .font(.system(size: 6, weight: .semibold))
                                        .lineLimit(1)
                                        .foregroundStyle(.red)
                                        .frame(height: 8)
                                    DayEventDots(colors: dayEventColors(on: day), isDark: colorScheme == .dark, maxCount: 2)
                                }
                                .frame(maxWidth: .infinity, minHeight: cellHeight, alignment: .top)
                            }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: cellHeight)
                        }
                    }
                }
                .padding(.top, gridTopPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func weekDays(for date: Date) -> [Date] {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = weekday - calendar.firstWeekday
        let weekStart = calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func monthGridDays(for date: Date) -> [Date?] {
        let startOfDay = calendar.startOfDay(for: date)
        let comps = calendar.dateComponents([.year, .month], from: startOfDay)
        guard let monthStart = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let leading = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        let leadingPadding = leading >= 0 ? leading : leading + 7
        var days: [Date?] = Array(repeating: nil, count: leadingPadding)

        for day in range {
            var components = comps
            components.day = day
            days.append(calendar.date(from: components))
        }

        let trailingPadding = (7 - (days.count % 7)) % 7
        days.append(contentsOf: Array(repeating: nil, count: trailingPadding))
        return days
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = AppLocalization.locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    private func dayNumberText(_ date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }

    private func holidayName(on date: Date) -> String? {
        entry.holidayNames[dayKey(date)]
    }

    private func dayTextColor(for date: Date) -> Color {
        if holidayName(on: date) != nil { return .red }
        return isToday(date) ? .primary : .secondary
    }

    @ViewBuilder
    private func dayNumberView(for date: Date, font: Font, circleSize: CGFloat) -> some View {
        ZStack {
            if isToday(date) {
                Circle()
                    .fill(Color.secondary.opacity(0.20))
                    .frame(width: circleSize, height: circleSize)
            }
            Text(dayNumberText(date))
                .font(font)
                .fontWeight(isToday(date) ? .semibold : .regular)
                .foregroundStyle(dayTextColor(for: date))
        }
        .frame(height: circleSize)
    }

    private func dayEventColors(on date: Date) -> [Color] {
        let items = entry.items.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }

        var result: [Color] = []
        let qwerMembers = Set(items.filter { $0.source == .qwer }.flatMap { $0.members })
        for member in QWERMember.allCases where qwerMembers.contains(member) {
            result.append(qwerMemberColor(member))
        }

        result.append(contentsOf: items.compactMap { item in
            guard item.source == .user, let hex = item.userColorHex else { return nil }
            return Color(hex: hex)
        })

        return Array(result.prefix(5))
    }

    private func qwerMemberColor(_ member: QWERMember) -> Color {
        switch member {
        case .Q: return Color.white.opacity(0.9)
        case .W: return Color(red: 244 / 255, green: 175 / 255, blue: 199 / 255)
        case .E: return Color(red: 175 / 255, green: 205 / 255, blue: 244 / 255)
        case .R: return Color(red: 199 / 255, green: 232 / 255, blue: 199 / 255)
        }
    }

    private func timeText(for item: CalendarWidgetScheduleSummary) -> String {
        if item.isAllDay { return AppLocalization.localized(ko: "하루종일", en: "All Day") }
        guard let start = item.startTime else { return AppLocalization.localized(ko: "시간 미정", en: "Time TBD") }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = AppLocalization.locale
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let value = formatter.string(from: start)
        guard AppLocalization.prefersEnglish, item.source == .qwer else { return value }
        return "\(value) KST"
    }

    private func smallSortRule(_ lhs: CalendarWidgetScheduleSummary, _ rhs: CalendarWidgetScheduleSummary) -> Bool {
        if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay && !rhs.isAllDay }
        switch (lhs.startTime, rhs.startTime) {
        case (let l?, let r?):
            if l != r { return l < r }
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        default:
            break
        }
        return lhs.title < rhs.title
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = AppDateFormatterFactory.fixedDayKeyFormatter()
        return formatter.string(from: date)
    }

    private func deepLinkURL(for item: CalendarWidgetScheduleSummary) -> URL {
        deepLinkURL(for: item.date)
    }

    private func deepLinkURL(for date: Date) -> URL {
        var components = URLComponents()
        components.scheme = "rockcrabcalendar"
        components.host = "calendar"
        components.queryItems = [
            .init(name: "date", value: dayKey(date))
        ]
        return components.url ?? URL(string: "rockcrabcalendar://calendar")!
    }
}

private struct DayEventDots: View {
    let colors: [Color]
    let isDark: Bool
    let maxCount: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(colors.count, maxCount), id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(Color(white: isDark ? 0.5 : 0.8))
                        .frame(width: 7, height: 7)
                    Circle()
                        .fill(colors[i])
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(height: 8)
    }
}

private extension Color {
    init(hex: String) {
        let normalized = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: normalized)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

private struct TodayWidget: Widget {
    let kind = "RockCrabCalendarTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RockCrabCalendarWidgetProvider(period: .today)) { entry in
            WidgetRootView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("오늘 일정")
        .description("오늘 일정을 빠르게 확인합니다.")
        .supportedFamilies([.systemSmall])
    }
}

private struct WeekWidget: Widget {
    let kind = "RockCrabCalendarWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RockCrabCalendarWidgetProvider(period: .week)) { entry in
            WidgetRootView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("이번 주 일정")
        .description("이번 주 캘린더를 확인합니다.")
        .supportedFamilies([.systemMedium])
    }
}

private struct MonthWidget: Widget {
    let kind = "RockCrabCalendarMonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RockCrabCalendarWidgetProvider(period: .month)) { entry in
            WidgetRootView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("이번 달 일정")
        .description("이번 달 캘린더를 확인합니다.")
        .supportedFamilies([.systemLarge])
    }
}

@main
struct RockCrabCalendarWidgets: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        WeekWidget()
        MonthWidget()
    }
}
