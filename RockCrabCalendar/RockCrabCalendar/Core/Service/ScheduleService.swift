//
//  ScheduleService.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import Foundation
import FirebaseFirestore

final class ScheduleService {
    private let db = Firestore.firestore()
    private let collection = "schedules"
    
    // MARK: - Add Schedule
    func addSchedule(_ item: ScheduleItem) async throws {
        try db.collection(collection)
            .document(item.id.uuidString)
            .setData(from: item)
    }
    
    // MARK: - Fetch All Schedules
    func fetchSchedules() async throws -> [ScheduleItem] {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: ScheduleItem.self)
        }
    }
    
    // MARK: - Fetech Schedules for Specific Date
    func fetchSchedules(for date: Date) async throws -> [ScheduleItem] {
        let allSchedules = try await fetchSchedules()
        return allSchedules.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // MARK: - Delete Schedule
    func deleteSchedule(_ item: ScheduleItem) async throws {
        try await db.collection(collection)
            .document(item.id.uuidString)
            .delete()
    }
    
    // MARK: - Update Schedule
    func updateSchedule(_ item: ScheduleItem) async throws {
        try db.collection(collection)
            .document(item.id.uuidString)
            .setData(from: item)
    }
}
