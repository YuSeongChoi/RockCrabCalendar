//
//  ScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import Foundation
import RockCrabDomain

// Repository that composes remote/local data sources for QWER schedules.
public actor QWERScheduleService: ScheduleServiceProtocol, QWERScheduleRepository {
    public typealias Schedule = QWERScheduleItem

    private let remote: QWERScheduleRemoteDataSource
    private let local: QWERScheduleLocalDataSource

    // MARK: - Init
    public init(
        remote: QWERScheduleRemoteDataSource = FirestoreQWERScheduleRemoteDataSource(),
        local: QWERScheduleLocalDataSource = UserDefaultsQWERScheduleLocalDataSource()
    ) {
        self.remote = remote
        self.local = local
    }

    // Convenience for test injection (local store only).
    public init(userDefaults: UserDefaults) {
        self.remote = FirestoreQWERScheduleRemoteDataSource()
        self.local = UserDefaultsQWERScheduleLocalDataSource(userDefaults: userDefaults)
    }

    /// 로컬(UserDefaults)에 저장된 사용자 추가 QWER 일정만 반환합니다.
    public func fetchLocalOnly() async -> [Schedule] {
        await local.fetchLocalOnly()
    }

    /// 이 일정이 로컬(UserDefaults)에 저장된 사용자 추가 QWER 일정인지 확인합니다.
    public func isLocalSchedule(_ item: Schedule) async -> Bool {
        await local.isLocalSchedule(item)
    }

    /// 사용자 직접 추가용 (Firestore 업로드 없이 로컬에만 저장)
    public func saveLocalSchedule(_ item: Schedule) async {
        await local.saveLocalSchedule(item)
    }

    /// 로컬 QWER 일정 업데이트
    public func updateLocalSchedule(_ item: Schedule) async {
        await local.updateLocalSchedule(item)
    }

    /// 로컬 QWER 일정 삭제
    public func deleteLocalSchedule(_ item: Schedule) async {
        await local.deleteLocalSchedule(item)
    }

    /// 일정 추가 또는 업데이트 (동일 ID 문서가 있으면 update, 없으면 add)
    public func saveSchedule(_ schedule: Schedule) async throws {
        try await remote.saveSchedule(schedule)
    }

    public func updateSchedule(_ schedule: Schedule) async throws {
        try await remote.updateSchedule(schedule)
    }

    /// 여러 일정 한번에 업데이트/추가 (배치 방식)
    public func updateSchedule(_ schedules: [Schedule]) async throws {
        try await remote.updateSchedules(schedules)
    }

    /// 일정 삭제
    public func deleteSchedule(_ schedule: Schedule) async throws {
        try await remote.deleteSchedule(schedule)
    }

    /// 일정 가져오기
    public func fetchSchedule() async throws -> [Schedule] {
        // 1) Remote (official) schedules from Firestore
        let remoteSchedules = try await remote.fetchSchedules()

        // 2) Local (user-added) schedules from UserDefaults
        let locals = await local.fetchLocalOnly()

        // 3) Merge (remote first, then local). If id duplicates, keep first occurrence.
        var merged: [UUID: Schedule] = [:]
        for r in remoteSchedules { merged[r.id] = r }
        for l in locals { merged[l.id] = l }
        return Array(merged.values)
    }
}
