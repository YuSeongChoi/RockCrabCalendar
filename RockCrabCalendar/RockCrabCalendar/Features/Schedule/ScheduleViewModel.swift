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
            fetchSchedule(for: selectedDate)
        }
    }
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func fetchSchedule(for date: Date) {
        let selectedDateString = dateFormatter.string(from: date)
        
        db.collection("schedules")
            .whereField("dateString", isEqualTo: selectedDateString)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("🔥 스케줄 가져오기 실패: \(error.localizedDescription)")
                    return
                }
                
                do {
                    self?.schedules = try snapshot?.documents.compactMap {
                        try $0.data(as: ScheduleItem.self)
                    } ?? []
                } catch {
                    print("🔥 스케줄 디코딩 실패: \(error.localizedDescription)")
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
