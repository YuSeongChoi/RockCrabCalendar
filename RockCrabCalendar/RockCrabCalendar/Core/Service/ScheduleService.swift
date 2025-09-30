//
//  ScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import Foundation
import FirebaseFirestore

final class QWERScheduleService {
    private let db = Firestore.firestore()
    private let collection = "schedules"
    
    // MARK: - 일정 추가
    func addSchedule(_ item: QWERScheduleItem) async throws {
        try db.collection(collection)
            .document(item.id.uuidString)
            .setData(from: item)
    }
    
    // MARK: - 모든 일정 가져오기
    func fetchSchedules() async throws -> [QWERScheduleItem] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: QWERScheduleItem.self)
        }
    }

    /// 여러 일정을 한 번에 업서트(추가 또는 업데이트)합니다.
    /// - Parameter payloads: (docId, data) 쌍의 배열. data는 일정의 딕셔너리 형태입니다.
    func upsertBatch(_ payloads: [(docId: String, data: [String: Any])]) async throws {
        guard !payloads.isEmpty else { return }
        let batch = db.batch()
        for p in payloads {
            let ref = db.collection(collection).document(p.docId)
            batch.setData(p.data, forDocument: ref, merge: true)
        }
        try await batch.commit()
    }
}
