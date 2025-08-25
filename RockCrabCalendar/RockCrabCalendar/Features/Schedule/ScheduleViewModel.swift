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
    var schedules: [ScheduleItem] = []
    var selectedDate: Date = Date()
    var lastFetchedAt: Date? = nil
    
    // MARK: - Category Filter State
    private let categoryKey = "activeScheduleCategories"
    var activeCategories: Set<ScheduleCategory> = Set(ScheduleCategory.allCases)
    var isAllCategories: Bool { activeCategories.count == ScheduleCategory.allCases.count }
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let syncFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy년 MM월 dd일 HH:mm:ss"
        return f
    }()
    
    var lastSyncText: String {
        if let d = lastFetchedAt {
            return "동기화 날짜 : \(syncFormatter.string(from: d))"
        } else {
            return "동기화 날짜 : -"
        }
    }
    
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
    
    init() {
        if let raw = UserDefaults.standard.array(forKey: categoryKey) as? [String] {
            let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
            if !decoded.isEmpty { self.activeCategories = Set(decoded) }
        }
    }
    
    func uploadSchedules(schedules: [ScheduleItem]) {
        guard !schedules.isEmpty else { return }
        let collection = db.collection("schedules")
        let chunkSize = 400 // Firestore batch 제한(500) 대비 안전 여유
        var index = 0
        while index < schedules.count {
            let end = min(index + chunkSize, schedules.count)
            let slice = schedules[index..<end]
            let batch = db.batch()
            for s in slice {
                let docId = stableDocumentID(for: s)
                let ref = collection.document(docId)
                batch.setData(s.asDictionary, forDocument: ref, merge: true)
            }
            batch.commit { error in
                if let error = error {
                    print("🔥 업서트 배치 실패(\(index)-\(end)): \(error.localizedDescription)")
                } else {
                    print("✅ 업서트 배치 성공: \(index)-\(end)")
                }
            }
            index = end
        }
    }
    
    func fetchAllSchedules(force: Bool = false) {
        let cacheKey = "cachedSchedules"
        let lastFetchKey = "lastScheduleFetchDate"
        let now = Date()

        // 캐시에서 먼저 불러오기
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedSchedules = try? JSONDecoder().decode([ScheduleItem].self, from: cachedData) {
            self.schedules = cachedSchedules
        }

        // 마지막 fetch 시간이 24시간 이내면 Firestore 호출 안함
        if let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastFetchedAt = lastFetch
            let diff = Calendar.current.dateComponents([.hour], from: lastFetch, to: now)
            if !force, let hours = diff.hour, hours < 24 {
                print("⏳ 캐시 유효 – Firestore fetch 생략 (force == false)")
                return
            }
        }

        // Firestore에서 최신 데이터 fetch
        db.collection("schedules")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("🔥 전체 스케줄 가져오기 실패: \(error.localizedDescription)")
                    return
                }

                do {
                    let fetched = try snapshot?.documents.compactMap {
                        try $0.data(as: ScheduleItem.self)
                    } ?? []

                    DispatchQueue.main.async {
                        self?.schedules = fetched
                        self?.lastFetchedAt = now

                        // 캐시 저장
                        if let data = try? JSONEncoder().encode(fetched) {
                            UserDefaults.standard.set(data, forKey: cacheKey)
                            UserDefaults.standard.set(now, forKey: lastFetchKey)
                        }
                    }
                } catch {
                    print("🔥 전체 스케줄 디코딩 실패: \(error.localizedDescription)")
                }
            }
    }
    
    func eventColors(for date: Date) -> [Color] {
        let items = schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date) && passesCategory($0)
        }
        let members = Set(items.flatMap { $0.members })

        return QWERMember.allCases.compactMap { member in
            members.contains(member) ? memberColor(member) : nil
        }
    }

    func schedules(on date: Date? = nil) -> [ScheduleItem] {
        let target = date ?? selectedDate
        return schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: target) && passesCategory($0)
        }
    }
    
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
    
    ///  유저가 직접 추가할 수 있도록 하는 함수
    func addSchedule(_ schedule: ScheduleItem) {
        schedules.append(schedule)
        uploadSchedules(schedules: [schedule])
    }
    
    ///  현재 월에 해당하는 모든 스케줄 반환 (날짜 기준 필터링)
    var monthlySchedules: [ScheduleItem] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return [] }

        return schedules.filter {
            $0.date >= startOfMonth && $0.date <= endOfMonth && passesCategory($0)
        }
    }
}
