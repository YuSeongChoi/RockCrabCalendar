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
    @Published var selectedDate: Date = Date() {
        didSet {
            fetchMonthlySchedules(for: selectedDate)
        }
    }
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func fetchMonthlySchedules(for monthDate: Date) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return }

        db.collection("schedules")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth.addMonth(n: -1)))
            .whereField("date", isLessThan: Timestamp(date: calendar.date(byAdding: .day, value: 1, to: endOfMonth.addMonth(n: 1))!))
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("🔥 월간 스케줄 가져오기 실패: \(error.localizedDescription)")
                    return
                }

                do {
                    self?.schedules = try snapshot?.documents.compactMap {
                        try $0.data(as: ScheduleItem.self)
                    } ?? []
                } catch {
                    print("🔥 월간 스케줄 디코딩 실패: \(error.localizedDescription)")
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
        case .chodan: return .pastelChodan
        case .magenta: return .pastelMajenta
        case .hina: return .pastelHina
        case .siyo: return .pastelMing
        }
    }
}
