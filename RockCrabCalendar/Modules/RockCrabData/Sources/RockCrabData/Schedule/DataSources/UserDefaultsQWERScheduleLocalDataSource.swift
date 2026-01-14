//
//  UserDefaultsQWERScheduleLocalDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabShared
import RockCrabDomain

// UserDefaults-backed local data source for QWER schedules.
public actor UserDefaultsQWERScheduleLocalDataSource: QWERScheduleLocalDataSource {
    private let store: UserDefaults
    private let localKey = AppStorageKeys.qwerLocalSchedules
    private var localMap: [UUID: QWERScheduleItem] = [:]

    public init(userDefaults: UserDefaults = .standard) {
        self.store = userDefaults
    }

    public func fetchLocalOnly() async -> [QWERScheduleItem] {
        loadLocal()
        return Array(localMap.values)
    }

    public func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool {
        loadLocal()
        if localMap[item.id] != nil { return true }
        // Fallback: field-based match for legacy entries where id wasn't persisted
        let cal = Calendar.current
        return localMap.values.contains(where: { s in
            s.title == item.title &&
            s.time == item.time &&
            s.place == item.place &&
            cal.isDate(s.date, inSameDayAs: item.date) &&
            s.members == item.members &&
            s.category == item.category
        })
    }

    public func saveLocalSchedule(_ item: QWERScheduleItem) async {
        loadLocal()
        localMap[item.id] = item
        persistLocal()
    }

    public func updateLocalSchedule(_ item: QWERScheduleItem) async {
        loadLocal()
        var didUpdate = false

        // 1) ID 기반 업데이트
        if localMap[item.id] != nil {
            localMap[item.id] = item
            didUpdate = true
        } else {
            // 2) ID가 다를 수 있는 레거시 데이터 대비: 필드 기반으로 기존 항목 탐색 후 교체
            let cal = Calendar.current
            if let key = localMap.first(where: { _, s in
                s.title == item.title &&
                s.time == item.time &&
                s.place == item.place &&
                cal.isDate(s.date, inSameDayAs: item.date) &&
                s.members == item.members &&
                s.category == item.category
            })?.key {
                localMap.removeValue(forKey: key)
                localMap[item.id] = item
                didUpdate = true
                #if DEBUG
                AppLogger.debug("QWER Local: ID 미일치로 필드기반 업데이트 수행 (title:\(item.title))", category: .qwerService)
                #endif
            }
        }

        if !didUpdate {
            // 3) 기존 항목을 찾지 못한 경우: 신규 저장으로 처리
            localMap[item.id] = item
            #if DEBUG
            AppLogger.debug("QWER Local: 기존 항목을 찾지 못해 새로 저장 (title:\(item.title))", category: .qwerService)
            #endif
        }

        persistLocal()
    }

    public func deleteLocalSchedule(_ item: QWERScheduleItem) async {
        loadLocal()
        let removedByID = localMap.removeValue(forKey: item.id) != nil
        if !removedByID {
            let cal = Calendar.current
            if let key = localMap.first(where: { _, s in
                s.title == item.title &&
                s.time == item.time &&
                s.place == item.place &&
                cal.isDate(s.date, inSameDayAs: item.date) &&
                s.members == item.members &&
                s.category == item.category
            })?.key {
                localMap.removeValue(forKey: key)
                #if DEBUG
                AppLogger.debug("QWER Local: ID 미일치로 필드기반 삭제 수행 (title:\(item.title))", category: .qwerService)
                #endif
            } else {
                #if DEBUG
                AppLogger.debug("QWER Local: 삭제 대상 미발견 (id: \(item.id))", category: .qwerService)
                #endif
            }
        }
        persistLocal()
    }
}

// MARK: - Storage helpers
private extension UserDefaultsQWERScheduleLocalDataSource {
    func persistLocal() {
        let values = Array(localMap.values)
        do {
            let data = try JSONEncoder().encode(values)
            store.set(data, forKey: localKey)
        } catch {
            #if DEBUG
            AppLogger.error("QWER Local 저장 실패: \(error.localizedDescription)", category: .qwerService)
            #endif
        }
    }

    func loadLocal() {
        guard let data = store.data(forKey: localKey),
              let arr = try? JSONDecoder().decode([QWERScheduleItem].self, from: data) else {
            return
        }
        localMap.removeAll()
        for item in arr { localMap[item.id] = item }
    }
}
