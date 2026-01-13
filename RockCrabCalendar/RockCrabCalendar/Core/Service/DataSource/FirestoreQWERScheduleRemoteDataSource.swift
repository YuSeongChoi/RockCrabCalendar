//
//  FirestoreQWERScheduleRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import FirebaseFirestore
import CryptoKit

// Firestore-backed remote data source for QWER schedules.
actor FirestoreQWERScheduleRemoteDataSource: QWERScheduleRemoteDataSource {
    private let collection = "schedules"

    // Defer Firestore access until after FirebaseApp.configure() completes.
    private var db: Firestore { Firestore.firestore() }

    // 서버 저장용 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = AppDateFormats.serverDay
        return formatter
    }()

    func fetchSchedules() async throws -> [QWERScheduleItem] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: QWERScheduleItem.self)
        }
    }

    func saveSchedule(_ schedule: QWERScheduleItem) async throws {
        let docId = stableDocumentID(for: schedule)
        let data = schedule.asDictionary
        let docRef = db.collection(collection).document(docId)
        let snapshot = try await docRef.getDocument()

        if snapshot.exists {
            try await updateSchedule(schedule)
            #if DEBUG
            AppLogger.debug("기존 스케줄 발견 → 업데이트 수행: \(schedule.id)", category: .qwerService)
            #endif
        } else {
            try await docRef.setData(data)
            #if DEBUG
            AppLogger.debug("스케줄 신규 등록 성공: \(schedule.id)", category: .qwerService)
            #endif
        }
    }

    func updateSchedule(_ schedule: QWERScheduleItem) async throws {
        let docId = stableDocumentID(for: schedule)
        let data = schedule.asDictionary
        try await db.collection(collection)
            .document(docId)
            .setData(data, merge: true)
        #if DEBUG
        AppLogger.debug("QWER 단일 업데이트 성공: \(schedule.id)", category: .qwerService)
        #endif
    }

    func updateSchedules(_ schedules: [QWERScheduleItem]) async throws {
        guard !schedules.isEmpty else { return }

        let payloads: [(docId: String, data: [String: Any])] = schedules.map { s in
            let docId = stableDocumentID(for: s)
            return (docId, s.asDictionary)
        }

        try await upsertBatch(payloads)
        #if DEBUG
        AppLogger.debug("업서트 배치 성공: \(payloads.count)건", category: .qwerService)
        #endif
    }

    func deleteSchedule(_ schedule: QWERScheduleItem) async throws {
        let idUUID = schedule.id.uuidString
        let idStable = stableDocumentID(for: schedule)
        let col = db.collection(collection)

        // Try delete by UUID-based id
        try await col.document(idUUID).delete()
        #if DEBUG
        AppLogger.debug("삭제 성공 (uuid id): \(idUUID)", category: .qwerService)
        #endif

        // Also try delete by stable hash id (in case the document was saved with stable ID)
        try await col.document(idStable).delete()
        #if DEBUG
        AppLogger.debug("삭제 성공 (stable id): \(idStable)", category: .qwerService)
        #endif
    }

    // Firestore 문서 ID를 안정적으로 생성 (날짜+제목+장소+카테고리 기반 해시)
    private func stableDocumentID(for s: QWERScheduleItem) -> String {
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
