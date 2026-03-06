//
//  ScheduleViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import Foundation
import Combine
import CryptoKit
import RockCrabDomain
import RockCrabShared
#if canImport(WidgetKit)
import WidgetKit
#endif

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
    // 현재 활성화된 카테고리 집합 (기본: 전체)   
    var activeCategories: Set<ScheduleCategory> = Set(ScheduleCategory.allCases)
    // 모든 카테고리가 선택되어 있는지 여부
    var isAllCategories: Bool { activeCategories.count == ScheduleCategory.allCases.count }
    
    private let useCase: QWERScheduleUseCase
    private let cacheStore: ScheduleCacheStoreProtocol
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

    private func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
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

    private func mergeLocalSchedules(
        base: [QWERScheduleItem],
        locals: [QWERScheduleItem]
    ) -> [QWERScheduleItem] {
        guard !locals.isEmpty else { return base }
        var merged = base
        var indexByID: [UUID: Int] = [:]
        for (index, item) in merged.enumerated() {
            indexByID[item.id] = index
        }
        for local in locals {
            if let index = indexByID[local.id] {
                merged[index] = local
            } else {
                merged.append(local)
                indexByID[local.id] = merged.count - 1
            }
        }
        return merged
    }
    
    // Inject use-case for DI and testability.
    init(useCase: QWERScheduleUseCase,
         cacheStore: ScheduleCacheStoreProtocol) {
        self.useCase = useCase
        self.cacheStore = cacheStore
        if let saved = useCase.loadActiveCategories(cacheStore: cacheStore) {
            self.activeCategories = saved
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
    // Add local schedule via use-case to keep ViewModel storage-agnostic.
    func addLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await useCase.addLocal(item)
            upsertLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .add, item: item))
            reloadWidgetTimelines()
        }
    }

    // Update local schedule via use-case to keep ViewModel storage-agnostic.
    func updateLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await useCase.updateLocal(item)
            upsertLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .update, item: item))
            reloadWidgetTimelines()
        }
    }

    // Delete local schedule via use-case to keep ViewModel storage-agnostic.
    func deleteLocal(_ item: QWERScheduleItem) {
        Task { @MainActor in
            await useCase.deleteLocal(item)
            removeLocalInMemory(item)
            QWERScheduleViewModel.localChangeSubject.send(.init(sourceID: instanceID, op: .delete, item: item))
            reloadWidgetTimelines()
        }
    }
    
    // 일정 추가
    // Add remote schedule via use-case to keep ViewModel storage-agnostic.
    func addSchedule(_ item: QWERScheduleItem) {
        Task {
            do {
                try await useCase.add(item)
            } catch {
                AppLogger.error("QWER 스케줄 저장 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // 일정 업데이트
    // Update remote schedule via use-case to keep ViewModel storage-agnostic.
    func updateSchedule(schedule: QWERScheduleItem) {
        Task {
            do {
                try await useCase.update(schedule)
            } catch {
                AppLogger.error("QWER 스케줄 업데이트 실패: \(error.localizedDescription)", category: .scheduleVM)
            }
        }
    }
    
    // Firestore에서 전체 스케줄을 가져오기 (캐시 우선)
    // force == true 인 경우에만 서버 동기화를 수행합니다.
    func fetchAllSchedules(force: Bool = false) {
        if force {
            Task { @MainActor [weak self] in
                guard let self else { return }
                _ = await self.syncServerSchedules()
            }
            return
        }

        loadCachedAndLocalSchedules()
    }

    // 서버 요청 없이 캐시+로컬 일정만 로드합니다.
    func loadCachedAndLocalSchedules() {
        let cache = useCase.loadCache(cacheStore: cacheStore)
        let cached = cache.schedules ?? []
        lastFetchedAt = cache.lastFetchedAt

        Task { @MainActor [weak self] in
            guard let self else { return }
            let locals = await self.useCase.fetchLocalOnly()
            self.schedules = self.mergeLocalSchedules(base: cached, locals: locals)
        }
    }

    // 설정 화면의 수동 동작에서만 호출되는 서버 동기화 API입니다.
    @MainActor
    @discardableResult
    func syncServerSchedules() async -> Bool {
        guard !isFetching else { return false }
        isFetching = true
        defer { isFetching = false }

        let now = Date()
        do {
            let fetched = try await useCase.refreshAndCache(cacheStore: cacheStore, now: now)
            schedules = fetched
            lastFetchedAt = now
            reloadWidgetTimelines()
            return true
        } catch {
            AppLogger.error("전체 스케줄 가져오기 실패: \(error.localizedDescription)", category: .scheduleVM)
            return false
        }
    }

    // 서버에서 가져온 캐시 일정만 삭제하고, 로컬 일정은 유지합니다.
    @MainActor
    func clearFetchedServerSchedules() async {
        useCase.clearCache(cacheStore: cacheStore)
        lastFetchedAt = nil
        let locals = await useCase.fetchLocalOnly()
        schedules = mergeLocalSchedules(base: [], locals: locals)
        reloadWidgetTimelines()
    }
}

// MARK: - Local check
extension QWERScheduleViewModel {
    // Check whether a schedule is local-only via use-case.
    func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool {
        await useCase.isLocal(item)
    }
}

// MARK: - Categories
extension QWERScheduleViewModel {
    // 특정 날짜(또는 선택된 날짜)의 스케줄 반환
    func schedules(on date: Date? = nil) -> [QWERScheduleItem] {
        let target = date ?? selectedDate
        return schedules.filter {
            Calendar.current.isDate($0.date, inSameDayAs: target) && passesCategory($0)
        }
    }

    func schedules(in range: DateInterval, categories: Set<ScheduleCategory>? = nil) -> [QWERScheduleItem] {
        let active = categories ?? activeCategories
        return schedules.filter { item in
            item.date >= range.start && item.date <= range.end && active.contains(item.category)
        }.sorted { $0.date < $1.date }
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
        useCase.saveActiveCategories(activeCategories, cacheStore: cacheStore)
    }

    private func passesCategory(_ item: QWERScheduleItem) -> Bool {
        activeCategories.contains(item.category)
    }
}

// MARK: - 스태틱 일정 업로드
extension QWERScheduleViewModel {
    func uploadDefaultQWERSchedules() {
        QWERScheduleItem.schedules.forEach {
            addSchedule($0)
        }
    }
}
