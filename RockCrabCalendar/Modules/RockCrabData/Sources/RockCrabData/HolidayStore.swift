//
//  HolidayStore.swift
//  RockCrabCalendar
//
//  Stores holiday info in memory and UserDefaults.
//

import Foundation
import RockCrabDomain
import RockCrabShared

public final class HolidayStore: HolidayStoreProtocol {
    private var holidays: [Date: Holiday] = [:]
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()

    private let storageKey = AppStorageKeys.holidayCacheData
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = AppDateFormats.serverDay
        return f
    }()

    private let store: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
        loadFromCache()
        if holidays.isEmpty {
            loadBundledDefaults()
        }
    }

    public func name(on date: Date) -> String? {
        let key = calendar.startOfDay(for: date)
        return holidays[key]?.name
    }

    public func updateWithItems(_ items: [HolidayInfo]) {
        guard let decoded = decode(from: items) else { return }
        holidays = decoded
        if let data = try? JSONEncoder().encode(items) {
            store.set(data, forKey: storageKey)
        }
    }

    private func loadFromCache() {
        if let data = store.data(forKey: storageKey),
           let decoded = decode(from: data) {
            holidays = decoded
        }
    }

    private func loadBundledDefaults() {
        let defaults: [HolidayInfo] = []
        var map: [Date: Holiday] = [:]
        for item in defaults {
            if let date = formatter.date(from: item.date) {
                let key = calendar.startOfDay(for: date)
                map[key] = Holiday(date: key, name: item.name)
            }
        }
        holidays = map
    }

    private func decode(from data: Data) -> [Date: Holiday]? {
        guard let items = try? JSONDecoder().decode([HolidayInfo].self, from: data) else { return nil }
        return decode(from: items)
    }

    private func decode(from items: [HolidayInfo]) -> [Date: Holiday]? {
        var map: [Date: Holiday] = [:]
        for item in items {
            if let date = formatter.date(from: item.date) {
                let key = calendar.startOfDay(for: date)
                map[key] = Holiday(date: key, name: item.name)
            }
        }
        return map
    }
}

private struct Holiday: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    let date: Date
    let name: String
}
