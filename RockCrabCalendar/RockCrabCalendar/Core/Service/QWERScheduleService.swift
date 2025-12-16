//
//  ScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import Foundation
import FirebaseFirestore
import CryptoKit

actor QWERScheduleService: ScheduleServiceProtocol {
    typealias Schedule = QWERScheduleItem
    
    private let db = Firestore.firestore()
    private let collection = "schedules"
    
    // Local (UserDefaults) storage for user-added QWER schedules
    private let localKey = "localQWERSchedules"
    private var localMap: [UUID: Schedule] = [:]
    
    // 서버 저장용 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Local Persistence (UserDefaults)
    private func persistLocal() {
        let values = Array(localMap.values)
        do {
            let data = try JSONEncoder().encode(values)
            UserDefaults.standard.set(data, forKey: localKey)
        } catch {
            #if DEBUG
            print("🔥 QWER Local 저장 실패: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadLocal() {
        guard let data = UserDefaults.standard.data(forKey: localKey),
              let arr = try? JSONDecoder().decode([Schedule].self, from: data) else {
            return
        }
        localMap.removeAll()
        for item in arr { localMap[item.id] = item }
    }
    
    /// 로컬(UserDefaults)에 저장된 사용자 추가 QWER 일정만 반환합니다.
    func fetchLocalOnly() -> [Schedule] {
        loadLocal()
        return Array(localMap.values)
    }
    
    /// 이 일정이 로컬(UserDefaults)에 저장된 사용자 추가 QWER 일정인지 확인합니다.
    /// - Returns: 로컬 일정이면 true, 아니면 false
    func isLocalSchedule(_ item: Schedule) -> Bool {
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

    /// 사용자 직접 추가용 (Firestore 업로드 없이 로컬에만 저장)
    func saveLocalSchedule(_ item: Schedule) {
        loadLocal()
        localMap[item.id] = item
        persistLocal()
    }

    /// 로컬 QWER 일정 업데이트
    func updateLocalSchedule(_ item: Schedule) {
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
                print("🔄 QWER Local: ID 미일치로 필드기반 업데이트 수행 (title:\(item.title))")
                #endif
            }
        }

        if !didUpdate {
            // 3) 기존 항목을 찾지 못한 경우: 신규 저장으로 처리
            localMap[item.id] = item
            #if DEBUG
            print("➕ QWER Local: 기존 항목을 찾지 못해 새로 저장 (title:\(item.title))")
            #endif
        }

        persistLocal()
    }

    /// 로컬 QWER 일정 삭제
    func deleteLocalSchedule(_ item: Schedule) {
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
                print("🗑️ QWER Local: ID 미일치로 필드기반 삭제 수행 (title:\(item.title))")
                #endif
            } else {
                #if DEBUG
                print("⚠️ QWER Local: 삭제 대상 미발견 (id: \(item.id))")
                #endif
            }
        }
        persistLocal()
    }
    
    /// 일정 추가 또는 업데이트 (동일 ID 문서가 있으면 update, 없으면 add)
    func saveSchedule(_ schedule: Schedule) async throws {
        let docId = stableDocumentID(for: schedule)
        let data = schedule.asDictionary
        let docRef = db.collection(collection).document(docId)
        let snapshot = try await docRef.getDocument()

        if snapshot.exists {
            try await updateSchedule(schedule)
            #if DEBUG
            print("🔄 기존 스케줄 발견 → 업데이트 수행: \(schedule.id)")
            #endif
        } else {
            try await docRef.setData(data)
            #if DEBUG
            print("✅ 스케줄 신규 등록 성공: \(schedule.id)")
            #endif
        }
    }
    
    func updateSchedule(_ schedule: Schedule) async throws {
        let docId = stableDocumentID(for: schedule)
        let data = schedule.asDictionary
        try await db.collection(collection)
            .document(docId)
            .setData(data, merge: true)
        #if DEBUG
        print("✅ QWER 단일 업데이트 성공: \(schedule.id)")
        #endif
    }
    
    /// 여러 일정 한번에 업데이트/추가 (배치 방식)
    func updateSchedule(_ schedules: [Schedule]) async throws {
        guard !schedules.isEmpty else { return }

        let payloads: [(docId: String, data: [String: Any])] = schedules.map { s in
            let docId = stableDocumentID(for: s)
            return (docId, s.asDictionary)
        }

        try await self.upsertBatch(payloads)
        #if DEBUG
        print("✅ 업서트 배치 성공: \(payloads.count)건")
        #endif
    }
    
    /// 일정 삭제
    func deleteSchedule(_ schedule: Schedule) async throws {
        let idUUID = schedule.id.uuidString
        let idStable = stableDocumentID(for: schedule)
        let col = db.collection(collection)

        // Try delete by UUID-based id
        try await col.document(idUUID).delete()
        #if DEBUG
        print("🗑️ 삭제 성공 (uuid id): \(idUUID)")
        #endif

        // Also try delete by stable hash id (in case the document was saved with stable ID)
        try await col.document(idStable).delete()
        #if DEBUG
        print("🗑️ 삭제 성공 (stable id): \(idStable)")
        #endif
    }
    
    /// 일정 가져오기
    func fetchSchedule() async throws -> [Schedule] {
        // 1) Remote (official) schedules from Firestore
        let snapshot = try await db.collection(collection).getDocuments()
        let remote: [Schedule] = snapshot.documents.compactMap { document in
            try? document.data(as: Schedule.self)
        }

        // 2) Local (user-added) schedules from UserDefaults
        loadLocal()
        let locals = Array(localMap.values)

        // 3) Merge (remote first, then local). If id duplicates, keep first occurrence.
        var merged: [UUID: Schedule] = [:]
        for r in remote { merged[r.id] = r }
        for l in locals { merged[l.id] = l }
        return Array(merged.values)
    }
}

extension QWERScheduleService {
    // Firestore 문서 ID를 안정적으로 생성 (날짜+제목+장소+카테고리 기반 해시)
    private func stableDocumentID(for s: Schedule) -> String {
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
    
    /// 여러 일정을 한 번에 업서트(추가 또는 업데이트)합니다.
    /// - Parameter payloads: (docId, data) 쌍의 배열. data는 일정의 딕셔너리 형태입니다.
    private func upsertBatch(_ payloads: [(docId: String, data: [String: Any])]) async throws {
        guard !payloads.isEmpty else { return }
        let batch = db.batch()
        for p in payloads {
            let ref = db.collection(collection).document(p.docId)
            batch.setData(p.data, forDocument: ref, merge: true)
        }
        try await batch.commit()
    }
}
