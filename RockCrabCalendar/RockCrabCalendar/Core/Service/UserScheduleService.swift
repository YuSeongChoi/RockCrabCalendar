//
//  UserScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/29/25.
//

import Foundation

final class UserScheduleService: ScheduleServiceProtocol {
    typealias Schedule = UserScheduleItem
    
    private let userDefaultKey = "userSchedules"
    
    // Dictionary 기반 저장
    private var scheduleMap: [UUID: Schedule] = [:]
    // 외부에는 배열 형태로 제공
    var schedules: [Schedule] {
        return Array(scheduleMap.values)
    }
    
    init() {
        // 초기 생성 시 로드
        loadFromUserDefaults()
    }
    
    // MARK: - CRUD
    func saveSchedule(_ schedule: Schedule) async throws {
        // 항상 최신 상태를 로드한 뒤 저장 (다중 인스턴스 대비)
        loadFromUserDefaults()
        scheduleMap[schedule.id] = schedule
        saveToUserDefaults()
    }
    
    func updateSchedule(_ schedule: Schedule) async throws {
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
                print("🔄 UserScheduleService: ID 미일치로 필드기반 업데이트 수행 (title:\(schedule.title))")
                #endif
            }
        }

        if !didUpdate {
            // 기존 항목을 찾지 못한 경우: 신규 저장으로 처리
            scheduleMap[schedule.id] = schedule
            #if DEBUG
            print("➕ UserScheduleService: 기존 항목을 찾지 못해 새로 저장 (title:\(schedule.title))")
            #endif
        }

        saveToUserDefaults()
    }
    
    /// 전체 저장
    func updateSchedule(_ schedules: [Schedule]) async throws {
        // 항상 최신 상태를 로드한 뒤 일괄 업데이트 (다중 인스턴스 대비)
        loadFromUserDefaults()
        for s in schedules {
            scheduleMap[s.id] = s
        }
        saveToUserDefaults()
    }
    
    func deleteSchedule(_ schedule: Schedule) async throws {
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
                print("🗑️ UserScheduleService: ID 미일치로 필드기반 삭제 수행 (title:\(schedule.title))")
                #endif
            } else {
                #if DEBUG
                print("⚠️ UserScheduleService: 삭제 대상 미발견 (id: \(schedule.id)) — 맵 크기: \(beforeCount)")
                #endif
            }
        }

        saveToUserDefaults()
    }
    
    func fetchSchedule() async throws -> [Schedule] {
        loadFromUserDefaults()
        return schedules
    }
}

// MARK: - 내부 헬퍼
extension UserScheduleService {
    private func saveToUserDefaults() {
        let values = Array(scheduleMap.values)
        do {
            let data = try JSONEncoder().encode(values)
            UserDefaults.standard.set(data, forKey: userDefaultKey)
        } catch {
            print("🔥 UserScheduleService 저장 실패:", error.localizedDescription)
        }
    }
    
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultKey),
              let arr = try? JSONDecoder().decode([Schedule].self, from: data) else {
            return
        }
        // map 재구성
        scheduleMap.removeAll()
        for item in arr {
            scheduleMap[item.id] = item
        }
    }
}
