//
//  QWERScheduleUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabShared

// Repository abstraction for QWER schedules to enable DI and testing.
public protocol QWERScheduleRepository {
    func fetchSchedule() async throws -> [QWERScheduleItem]
    func saveSchedule(_ schedule: QWERScheduleItem) async throws
    func updateSchedule(_ schedule: QWERScheduleItem) async throws
    func deleteSchedule(_ schedule: QWERScheduleItem) async throws
    func fetchLocalOnly() async -> [QWERScheduleItem]
    func saveLocalSchedule(_ item: QWERScheduleItem) async
    func updateLocalSchedule(_ item: QWERScheduleItem) async
    func deleteLocalSchedule(_ item: QWERScheduleItem) async
    func isLocalSchedule(_ item: QWERScheduleItem) async -> Bool
}

// Use-case layer for QWER schedules, isolating ViewModel from storage details.
public struct QWERScheduleUseCase {
    private let repository: QWERScheduleRepository

    // Compose with a repository (Firestore/UserDefaults, mock, etc).
    public init(repository: QWERScheduleRepository) {
        self.repository = repository
    }

    // Fetch remote + local merged schedules.
    public func fetchAll() async throws -> [QWERScheduleItem] {
        try await repository.fetchSchedule()
    }

    public func loadActiveCategories(
        cacheStore: ScheduleCacheStoreProtocol
    ) -> Set<ScheduleCategory>? {
        cacheStore.loadActiveCategories()
    }

    public func saveActiveCategories(
        _ categories: Set<ScheduleCategory>,
        cacheStore: ScheduleCacheStoreProtocol
    ) {
        cacheStore.saveActiveCategories(categories)
    }

    // Load cached schedules and last fetch date.
    public func loadCache(
        cacheStore: ScheduleCacheStoreProtocol
    ) -> (schedules: [QWERScheduleItem]?, lastFetchedAt: Date?) {
        let cached = cacheStore.loadCachedSchedules()
        let lastFetch = cacheStore.loadLastFetchDate()
        return (cached, lastFetch)
    }

    // Decide whether a refresh is needed based on TTL and force flag.
    public func shouldRefresh(
        cacheStore: ScheduleCacheStoreProtocol,
        now: Date = Date(),
        cacheTTLHours: Int = 24,
        force: Bool
    ) -> Bool {
        guard !force else { return true }
        guard let lastFetch = cacheStore.loadLastFetchDate() else { return true }
        let diff = Calendar.current.dateComponents([.hour], from: lastFetch, to: now)
        return (diff.hour ?? cacheTTLHours) >= cacheTTLHours
    }

    // Fetch schedules and update cache metadata.
    public func refreshAndCache(
        cacheStore: ScheduleCacheStoreProtocol,
        now: Date = Date()
    ) async throws -> [QWERScheduleItem] {
        let fetched = try await repository.fetchSchedule()
        cacheStore.saveCachedSchedules(fetched)
        cacheStore.saveLastFetchDate(now)
        return fetched
    }

    // Clear cached server schedules and last fetch metadata.
    public func clearCache(cacheStore: ScheduleCacheStoreProtocol) {
        cacheStore.clearScheduleCache()
    }

    // Create or upsert a remote schedule.
    public func add(_ schedule: QWERScheduleItem) async throws {
        try await repository.saveSchedule(schedule)
    }

    // Update a remote schedule.
    public func update(_ schedule: QWERScheduleItem) async throws {
        try await repository.updateSchedule(schedule)
    }

    // Delete a remote schedule.
    public func delete(_ schedule: QWERScheduleItem) async throws {
        try await repository.deleteSchedule(schedule)
    }

    // Fetch local-only schedules.
    public func fetchLocalOnly() async -> [QWERScheduleItem] {
        await repository.fetchLocalOnly()
    }

    // Save a local-only schedule.
    public func addLocal(_ item: QWERScheduleItem) async {
        await repository.saveLocalSchedule(item)
    }

    // Update a local-only schedule.
    public func updateLocal(_ item: QWERScheduleItem) async {
        await repository.updateLocalSchedule(item)
    }

    // Delete a local-only schedule.
    public func deleteLocal(_ item: QWERScheduleItem) async {
        await repository.deleteLocalSchedule(item)
    }

    // Check whether the schedule is a local-only item.
    public func isLocal(_ item: QWERScheduleItem) async -> Bool {
        await repository.isLocalSchedule(item)
    }
}
