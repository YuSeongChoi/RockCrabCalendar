import Foundation
import RockCrabDomain
import RockCrabShared

struct CalendarWidgetDataStore {
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = AppGroupUserDefaults.shared) {
        self.userDefaults = userDefaults
    }

    func loadQWERSchedules() -> [QWERScheduleItem] {
        guard let data = userDefaults.data(forKey: AppStorageKeys.qwerScheduleCacheData),
              let decoded = try? decoder.decode([QWERScheduleItem].self, from: data) else {
            return []
        }
        return decoded
    }

    func loadLocalQWERSchedules() -> [QWERScheduleItem] {
        guard let data = userDefaults.data(forKey: AppStorageKeys.qwerLocalSchedules),
              let decoded = try? decoder.decode([QWERScheduleItem].self, from: data) else {
            return []
        }
        return decoded
    }

    func loadUserSchedules() -> [UserScheduleItem] {
        guard let data = userDefaults.data(forKey: AppStorageKeys.userSchedules),
              let decoded = try? decoder.decode([UserScheduleItem].self, from: data) else {
            return []
        }
        return decoded
    }

    func loadHolidayNameMap() -> [String: String] {
        guard let data = userDefaults.data(forKey: AppStorageKeys.holidayCacheData),
              let decoded = try? decoder.decode([HolidayInfo].self, from: data) else {
            return [:]
        }
        var map: [String: String] = [:]
        for item in decoded {
            map[item.date] = item.name
        }
        return map
    }
}
