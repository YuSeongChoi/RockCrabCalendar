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
    private var cancellables = Set<AnyCancellable>()
    private let instanceID = UUID()

    enum LocalOp: String { case add, update, delete }

    struct LocalChangeEvent {
        let sourceID: UUID
        let op: LocalOp
        let item: QWERScheduleItem
    }

    static let localChangeSubject = PassthroughSubject<LocalChangeEvent, Never>()
    private var isFetching = false
    private let cacheTTLHours: Int = 24
    
    // MARK: - Local (in-memory) partial updates
    private func upsertLocalInMemory(_ item: QWERScheduleItem) {
        if let idx = schedules.firstIndex(where: { $0.id == item.id }) {
            schedules[idx] = item
        } else {
            schedules.append(item)
        }
    }

    private func removeLocalInMemory(_ item: QWERScheduleItem) {
        if let idx = schedules.firstIndex(where: { $0.id == item.id }) {
            schedules.remove(at: idx)
        } else {
            // Fallback: field-based match in case of legacy ids
            let cal = Calendar.current
            if let idx = schedules.firstIndex(where: { s in
                s.title == item.title &&
//                s.time == item.time &&
                s.place == item.place &&
                cal.isDate(s.date, inSameDayAs: item.date) &&
                s.members == item.members &&
                s.category == item.category
            }) {
                schedules.remove(at: idx)
            }
        }
    }
    
    init(service: QWERScheduleService = QWERScheduleService()) {
        self.service = service
        if let raw = UserDefaults.standard.array(forKey: categoryKey) as? [String] {
            let decoded = raw.compactMap { ScheduleCategory(rawValue: $0) }
            if !decoded.isEmpty { self.activeCategories = Set(decoded) }
        }
        // Observe local schedule changes coming from other instances
        QWERScheduleViewModel.localChangeSubject
            .filter { [weak self] event in
                guard let self else { return false }
                return event.sourceID != self.instanceID
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event.op {
                case .add, .update:
                    self.upsertLocalInMemory(event.item)
                case .delete:
                    self.removeLocalInMemory(event.item)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Local-only mutations (no fetch)
    func addLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await service.saveLocalSchedule(item)
            upsertLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .add, item: item))
        }
    }

    func updateLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await service.updateLocalSchedule(item)
            upsertLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .update, item: item))
        }
    }

    func deleteLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await service.deleteLocalSchedule(item)
            removeLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .delete, item: item))
        }
    }
    
    // 일정 추가
    func addSchedule(_ item: QWERScheduleItem) {
        Task {
            do {
                try await service.saveSchedule(item)
            } catch {
                print("🔥 QWER 스케줄 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 일정 업데이트
    func updateSchedule(schedule: QWERScheduleItem) {
        Task {
            do {
                try await service.updateSchedule(schedule)
            } catch {
                print("🔥 QWER 스케줄 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // Firestore에서 전체 스케줄을 가져오기 (캐시 우선)
    func fetchAllSchedules(force: Bool = false) {
        let cacheKey = "cachedSchedules"
        let lastFetchKey = "lastScheduleFetchDate"
        let now = Date()

        if isFetching {
            return
        }

        // 1) Cache-first
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedSchedules = try? JSONDecoder().decode([QWERScheduleItem].self, from: cachedData) {
            self.schedules = cachedSchedules
        }

        if let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastFetchedAt = lastFetch
            let diff = Calendar.current.dateComponents([.hour], from: lastFetch, to: now)
            if !force, let hours = diff.hour, hours < cacheTTLHours {
                print("⏳ 캐시 유효 – Service fetch 생략 (force == false)")
                return
            }
        }

        // 2) Network
        Task { @MainActor [weak self] in
            guard let self else { return }
            isFetching = true
            defer { isFetching = false }
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
