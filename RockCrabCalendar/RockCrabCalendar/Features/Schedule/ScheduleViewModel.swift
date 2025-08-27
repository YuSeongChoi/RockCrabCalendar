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
final class ScheduleViewModel {
    // 현재 로드된 모든 스케줄
    var schedules: [ScheduleItem] = []
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
    
    private let service: ScheduleService
    private var cancellables = Set<AnyCancellable>()
    // 서버 저장용 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
    
    // Firestore 문서 ID를 안정적으로 생성 (날짜+제목+장소+카테고리 기반 해시)
    private func stableDocumentID(for s: ScheduleItem) -> String {
        // 날짜는 yyyy-MM-dd 로 고정
        let dateKey = dateFormatter.string(from: s.date)
        // 제목/장소는 소문자 + 트리밍 + 내부 공백을 단일 공백으로 정규화
        func norm(_ str: String) -> String {
            str
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .lowercased()
        }
        let titleKey = norm(s.title)
        let placeKey = norm(s.place)
        let catKey = s.category.rawValue.lowercased()
        let raw = "\(dateKey)|\(titleKey)|\(placeKey)|\(catKey)"
        // SHA256 해시 → 앞 20자(80bit)만 사용해서 짧고 충돌 가능성 낮게
        let digest = SHA256.hash(data: Data(raw.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "rc_" + String(hex.prefix(20))
    }
    
    init(service: ScheduleService = ScheduleService()) {
        self.service = service
        if let raw = UserDefaults.standard.array(forKey: categoryKey) as? [String] {
            let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
            if !decoded.isEmpty { self.activeCategories = Set(decoded) }
        }
    }
    
    // 여러 스케줄을 Firestore에 업서트
    func uploadSchedules(schedules: [ScheduleItem]) {
        guard !schedules.isEmpty else { return }
        let payloads: [(docId: String, data: [String: Any])] = schedules.map { s in
            let docId = stableDocumentID(for: s)
            return (docId, s.asDictionary)
        }
        
        Task {
            do {
                try await service.upsertBatch(payloads)
                print("✅ 업서트 배치 성공: \(payloads.count)건")
            } catch {
                print("🔥 업서트 배치 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // Firestore에서 전체 스케줄을 가져오기 (캐시 우선)
    func fetchAllSchedules(force: Bool = false) {
        let cacheKey = "cachedSchedules"
        let lastFetchKey = "lastScheduleFetchDate"
        let now = Date()

        // 1) Cache-first
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedSchedules = try? JSONDecoder().decode([ScheduleItem].self, from: cachedData) {
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
        Task { [weak self] in
            do {
                let fetched = try await self?.service.fetchSchedules() ?? []
                await MainActor.run {
                    self?.schedules = fetched
                    self?.lastFetchedAt = now
                    if let data = try? JSONEncoder().encode(fetched) {
                        UserDefaults.standard.set(data, forKey: cacheKey)
                        UserDefaults.standard.set(now, forKey: lastFetchKey)
                    }
                }
            } catch {
                print("🔥 전체 스케줄 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
    
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
    func schedules(on date: Date? = nil) -> [ScheduleItem] {
        let target = date ?? selectedDate
        return schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: target) && passesCategory($0)
        }
    }
    
    // 카테고리 선택/토글/저장
    private func persistCategories() {
        let raw = activeCategories.map { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: categoryKey)
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

    private func passesCategory(_ item: ScheduleItem) -> Bool {
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

// MARK: - ScheduleViewModel Extensions (기능 추가)
extension ScheduleViewModel {
    /// 일정 타입 필터링용
//    func schedules(for type: ScheduleType?) -> [ScheduleItem] {
//        guard let type = type else { return schedules }
//        return schedules.filter { $0.scheduleType == type }
//    }
    
    // 유저가 직접 스케줄 추가
    func addSchedule(_ schedule: ScheduleItem) {
        schedules.append(schedule)
        uploadSchedules(schedules: [schedule])
    }
    
    // 현재 월의 모든 스케줄 반환
    var monthlySchedules: [ScheduleItem] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return [] }

        return schedules.filter {
            $0.date >= startOfMonth && $0.date <= endOfMonth && passesCategory($0)
        }
    }
}
