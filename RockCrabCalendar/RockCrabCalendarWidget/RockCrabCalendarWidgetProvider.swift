import Foundation
import WidgetKit
import RockCrabDomain

struct RockCrabCalendarWidgetProvider: TimelineProvider {
    typealias Entry = RockCrabCalendarWidgetEntry

    let period: CalendarWidgetPeriod
    private let store = CalendarWidgetDataStore()
    private let useCase = CalendarWidgetSnapshotUseCase()

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), period: period, items: [], holidayNames: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(makeEntry(now: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        let entry = makeEntry(now: now)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry(now: Date) -> Entry {
        let qwerCached = store.loadQWERSchedules()
        let qwerLocal = store.loadLocalQWERSchedules()
        let qwer = mergeQWERSchedules(cached: qwerCached, local: qwerLocal)
        let user = store.loadUserSchedules()
        let holidayNames = store.loadHolidayNameMap()
        let items = useCase.makeSnapshot(
            period: period,
            baseDate: now,
            qwerSchedules: qwer,
            userSchedules: user
        )
        return Entry(date: now, period: period, items: items, holidayNames: holidayNames)
    }

    private func mergeQWERSchedules(
        cached: [QWERScheduleItem],
        local: [QWERScheduleItem]
    ) -> [QWERScheduleItem] {
        guard !local.isEmpty else { return cached }

        var merged = cached
        var indexByID: [UUID: Int] = [:]
        for (idx, item) in merged.enumerated() {
            indexByID[item.id] = idx
        }

        for item in local {
            if let idx = indexByID[item.id] {
                merged[idx] = item
            } else {
                merged.append(item)
                indexByID[item.id] = merged.count - 1
            }
        }
        return merged
    }
}
