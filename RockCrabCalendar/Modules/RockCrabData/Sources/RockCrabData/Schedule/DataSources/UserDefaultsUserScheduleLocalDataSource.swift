//
//  UserDefaultsUserScheduleLocalDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabShared
import RockCrabDomain

// UserDefaults-backed local data source for user schedules.
public actor UserDefaultsUserScheduleLocalDataSource: UserScheduleLocalDataSource {
    private let userDefaultKey = AppStorageKeys.userSchedules
    private let store: UserDefaults

    // Dictionary 기반 저장
    private var scheduleMap: [UUID: UserScheduleItem] = [:]

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
        self.scheduleMap = Self.decodeScheduleMap(
            from: userDefaults.data(forKey: AppStorageKeys.userSchedules)
        )
    }

    public func saveSchedule(_ schedule: UserScheduleItem) async throws {
        // 항상 최신 상태를 로드한 뒤 저장 (다중 인스턴스 대비)
        loadFromUserDefaults()
        scheduleMap[schedule.id] = schedule
        saveToUserDefaults()
    }

    public func updateSchedule(_ schedule: UserScheduleItem) async throws {
        // 항상 최신 상태를 로드한 뒤 업데이트 (다중 인스턴스 대비)
        loadFromUserDefaults()

        var didUpdate = false
        if scheduleMap[schedule.id] != nil {
            scheduleMap[schedule.id] = schedule
            didUpdate = true
        } else {
            // 레거시 데이터 대비: 필드 기반으로 기존 항목 탐색 후 교체
            let cal = Calendar.current
            if let key = scheduleMap.first(where: { _, s in
                s.title == schedule.title &&
//                s.time == schedule.time &&
                s.place == schedule.place &&
                cal.isDate(s.date, inSameDayAs: schedule.date)
            })?.key {
                scheduleMap.removeValue(forKey: key)
                scheduleMap[schedule.id] = schedule
                didUpdate = true
                #if DEBUG
                AppLogger.debug("UserScheduleService: ID 미일치로 필드기반 업데이트 수행 (title:\(schedule.title))", category: .userService)
                #endif
            }
        }

        if !didUpdate {
            // 기존 항목을 찾지 못한 경우: 신규 저장으로 처리
            scheduleMap[schedule.id] = schedule
            #if DEBUG
            AppLogger.debug("UserScheduleService: 기존 항목을 찾지 못해 새로 저장 (title:\(schedule.title))", category: .userService)
            #endif
        }

        saveToUserDefaults()
    }

    public func updateSchedule(_ schedules: [UserScheduleItem]) async throws {
        // 항상 최신 상태를 로드한 뒤 일괄 업데이트 (다중 인스턴스 대비)
        loadFromUserDefaults()
        for s in schedules {
            scheduleMap[s.id] = s
        }
        saveToUserDefaults()
    }

    public func deleteSchedule(_ schedule: UserScheduleItem) async throws {
        // 항상 최신 상태를 로드한 뒤 삭제 (다중 인스턴스 대비)
        loadFromUserDefaults()

        let beforeCount = scheduleMap.count
        // 1) ID 기반 삭제
        let removedByID = scheduleMap.removeValue(forKey: schedule.id) != nil

        if !removedByID {
            // 2) ID가 다를 수 있는 경우를 대비해 필드 매칭으로 보조 삭제
            let cal = Calendar.current
            if let key = scheduleMap.first(where: { _, s in
                s.title == schedule.title &&
//                s.time == schedule.time &&
                s.place == schedule.place &&
                cal.isDate(s.date, inSameDayAs: schedule.date)
            })?.key {
                scheduleMap.removeValue(forKey: key)
                #if DEBUG
                AppLogger.debug("UserScheduleService: ID 미일치로 필드기반 삭제 수행 (title:\(schedule.title))", category: .userService)
                #endif
            } else {
                #if DEBUG
                AppLogger.debug("UserScheduleService: 삭제 대상 미발견 (id: \(schedule.id)) — 맵 크기: \(beforeCount)", category: .userService)
                #endif
            }
        }

        saveToUserDefaults()
    }

    public func fetchSchedule() async throws -> [UserScheduleItem] {
        loadFromUserDefaults()
        return Array(scheduleMap.values)
    }
}

// MARK: - Storage helpers
private extension UserDefaultsUserScheduleLocalDataSource {
    static func decodeScheduleMap(from data: Data?) -> [UUID: UserScheduleItem] {
        guard let data,
              let arr = try? JSONDecoder().decode([UserScheduleItem].self, from: data) else {
            return [:]
        }

        var map: [UUID: UserScheduleItem] = [:]
        for item in arr {
            map[item.id] = item
        }
        return map
    }

    func saveToUserDefaults() {
        let values = Array(scheduleMap.values)
        do {
            let data = try JSONEncoder().encode(values)
            store.set(data, forKey: userDefaultKey)
        } catch {
            AppLogger.error("UserScheduleService 저장 실패: \(error.localizedDescription)", category: .userService)
        }
    }

    func loadFromUserDefaults() {
        scheduleMap = Self.decodeScheduleMap(from: store.data(forKey: userDefaultKey))
    }
}
