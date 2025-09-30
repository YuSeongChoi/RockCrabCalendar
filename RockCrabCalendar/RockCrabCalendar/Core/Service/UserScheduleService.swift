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
    
    // MARK: - CRUD
    func saveSchedule(_ schedule: Schedule) {
        scheduleMap[schedule.id] = schedule
        saveToUserDefaults()
    }
    
    func updateSchedule(_ schedule: Schedule) {
        scheduleMap[schedule.id] = schedule
        saveToUserDefaults()
    }
    
    /// 전체 저장
    func updateSchedule(_ schedules: [Schedule]) {
        for s in schedules {
            scheduleMap[s.id] = s
        }
        saveToUserDefaults()
    }
    
    func deleteSchedule(_ schedule: Schedule) {
        scheduleMap.removeValue(forKey: schedule.id)
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
