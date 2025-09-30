//
//  ScheduleViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import Foundation
import FirebaseFirestore
import Combine
import SwiftUI
import CryptoKit

@Observable
final class QWERScheduleViewModel {
    // 현재 로드된 모든 스케줄
    var schedules: [QWERScheduleItem] = []
    // 사용자가 선택한 날짜 (기본값: 오늘)
    var selectedDate: Date = Date()
    // 마지막으로 동기화한 시각
    var lastFetchedAt: Date? = nil
    
    // MARK: - 카테고리 필터 상태
    // 카테고리 상태를 UserDefaults에 저장하기 위한 키
    private let categoryKey = "activeScheduleCategories"
    // 현재 활성화된 카테고리 집합 (기본: 전체)
    var activeCategories: Set<ScheduleCategory> = Set(ScheduleCategory.allCases)
    // 모든 카테고리가 선택되어 있는지 여부
    var isAllCategories: Bool { activeCategories.count == ScheduleCategory.allCases.count }
    
    private let service: QWERScheduleService
    
    // 동기화 시간 표시용 포맷터
    private let syncFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy년 MM월 dd일 HH:mm:ss"
        return f
    }()
    
    // 마지막 동기화 시간을 문자열로 반환
    var lastSyncText: String {
        if let d = lastFetchedAt {
            return "동기화 날짜 : \(syncFormatter.string(from: d))"
        } else {
            return "동기화 날짜 : -"
        }
    }
    
    init(service: QWERScheduleService = QWERScheduleService()) {
        self.service = service
        if let raw = UserDefaults.standard.array(forKey: categoryKey) as? [String] {
            let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
            if !decoded.isEmpty { self.activeCategories = Set(decoded) }
        }
    }
    
    // 일정 추가
    func addSchedule(_ item: QWERScheduleItem) {
        service.addSchedule(item)
    }
    
    // 일정 업데이트
    func updateSchedule(schedules: [QWERScheduleItem]) {
        service.updateSchedule(schedules)
    }
    
    // Firestore에서 전체 스케줄을 가져오기 (캐시 우선)
    func fetchAllSchedules(force: Bool = false) {
        let cacheKey = "cachedSchedules"
        let lastFetchKey = "lastScheduleFetchDate"
        let now = Date()

        // 1) Cache-first
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedSchedules = try? JSONDecoder().decode([QWERScheduleItem].self, from: cachedData) {
            self.schedules = cachedSchedules
        }

        if let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastFetchedAt = lastFetch
            let diff = Calendar.current.dateComponents([.hour], from: lastFetch, to: now)
            if !force, let hours = diff.hour, hours < 24 {
                print("⏳ 캐시 유효 – Service fetch 생략 (force == false)")
                return
            }
        }

        // 2) Network
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let fetched = try await self.service.fetchSchedule()
                self.schedules = fetched
                self.lastFetchedAt = now
                if let data = try? JSONEncoder().encode(fetched) {
                    UserDefaults.standard.set(data, forKey: cacheKey)
                    UserDefaults.standard.set(now, forKey: lastFetchKey)
                }
            } catch {
                print("🔥 전체 스케줄 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 멤버들 색상관련
extension QWERScheduleViewModel {
    // 특정 날짜에 해당하는 스케줄들의 멤버 색상 반환
    func eventColors(for date: Date) -> [Color] {
        let items = schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date) && passesCategory($0)
        }
        let members = Set(items.flatMap { $0.members })

        return QWERMember.allCases.compactMap { member in
            members.contains(member) ? memberColor(member) : nil
        }
    }

    // 특정 날짜(또는 선택된 날짜)의 스케줄 반환
    func schedules(on date: Date? = nil) -> [QWERScheduleItem] {
        let target = date ?? selectedDate
        return schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: target) && passesCategory($0)
        }
    }

    func toggleCategory(_ category: ScheduleCategory) {
        if activeCategories.contains(category) { activeCategories.remove(category) }
        else { activeCategories.insert(category) }
        persistCategories()
    }

    func setAllCategories() {
        activeCategories = Set(ScheduleCategory.allCases)
        persistCategories()
    }

    func setCategories(_ categories: Set<ScheduleCategory>) {
        activeCategories = categories.isEmpty ? Set(ScheduleCategory.allCases) : categories
        persistCategories()
    }
    
    // 카테고리 선택/토글/저장
    private func persistCategories() {
        let raw = activeCategories.map { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: categoryKey)
    }

    private func passesCategory(_ item: QWERScheduleItem) -> Bool {
        activeCategories.contains(item.category)
    }
    
    // 멤버별 대표 파스텔 색상
    func memberColor(_ member: QWERMember) -> Color {
        switch member {
        case .Q: return .pastelChodan
        case .W: return .pastelMagenta
        case .E: return .pastelHina
        case .R: return .pastelMing
        }
    }
}
