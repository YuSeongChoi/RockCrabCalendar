import Foundation
import WidgetKit
import RockCrabDomain

struct RockCrabCalendarWidgetEntry: TimelineEntry {
    let date: Date
    let period: CalendarWidgetPeriod
    let items: [CalendarWidgetScheduleSummary]
    let holidayNames: [String: String]
}
