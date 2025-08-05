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

final class ScheduleViewModel: ObservableObject {
    @Published var schedules: [ScheduleItem] = []
    @Published var selectedDate: Date = Date()
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func uploadSchedules(schedules: [ScheduleItem]) {
        for schedule in schedules {
            db.collection("schedules")
                .document(schedule.id.uuidString)
                .setData(schedule.asDictionary, merge: true) { error in
                    if let error = error {
                        print("🔥 업로드 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ 업로드 성공 (업데이트 포함): \(schedule.title)")
                    }
                }
        }
    }
    
    func fetchAllSchedules() {
        db.collection("schedules")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("🔥 전체 스케줄 가져오기 실패: \(error.localizedDescription)")
                    return
                }

                do {
                    self?.schedules = try snapshot?.documents.compactMap {
                        try $0.data(as: ScheduleItem.self)
                    } ?? []
                } catch {
                    print("🔥 전체 스케줄 디코딩 실패: \(error.localizedDescription)")
                }
            }
    }
    
    func eventColors(for date: Date) -> [Color] {
        let items = schedules.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let members = Set(items.flatMap { $0.members })
        
        return QWERMember.allCases.compactMap { member in
            members.contains(member) ? memberColor(member) : nil
        }
    }
    
    private func memberColor(_ member: QWERMember) -> Color {
        switch member {
        case .Q: return .pastelChodan
        case .W: return .pastelMajenta
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
            $0.date >= startOfMonth && $0.date <= endOfMonth
        }
    }
}
