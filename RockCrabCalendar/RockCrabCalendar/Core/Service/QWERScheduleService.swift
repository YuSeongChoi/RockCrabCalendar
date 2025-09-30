//
//  ScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import Foundation
import FirebaseFirestore
import CryptoKit

final class QWERScheduleService: ScheduleServiceProtocol {
    typealias Schedule = QWERScheduleItem
    
    private let db = Firestore.firestore()
    private let collection = "schedules"
    
    // 서버 저장용 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 일정 추가
    func addSchedule(_ item: Schedule) {
        let data = item.asDictionary
        db.collection(collection)
            .document(item.id.uuidString)
            .setData(data) { error in
                if let error = error {
                    print("🔥 스케줄 등록 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 스케줄 등록 성공")
                }
            }
    }
    
    /// 일정 업데이트
    func updateSchedule(_ schedules: [Schedule]) {
        guard !schedules.isEmpty else { return }
        
        let payloads: [(docId: String, data: [String: Any])] = schedules.map { s in
            let docId = stableDocumentID(for: s)
            return (docId, s.asDictionary)
        }
        
        Task {
            do {
                try await self.upsertBatch(payloads)
                print("✅ 업서트 배치 성공: \(payloads.count)건")
            } catch {
                print("🔥 업서트 배치 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 일정 삭제
    func deleteSchedule(_ schedule: Schedule) {
        db.collection(collection)
            .document(schedule.id.uuidString)
            .delete { error in
                if let error = error {
                    print("🔥 삭제 실패: \(error.localizedDescription)")
                } else {
                    print("🗑️ 삭제 성공: \(schedule.id)")
                }
            }
    }
    
    /// 일정 가져오기
    func fetchSchedule() async throws -> [Schedule] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Schedule.self)
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

extension QWERScheduleService {
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
}
