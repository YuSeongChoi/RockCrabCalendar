//
//  CalendarViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import SwiftUI
import Combine

final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date() {
        didSet { generateDays() }
    }
    @Published var days: [Date] = []
    @Published var selectedDate: Date = Date()
    @Published var eventColorMap: [Date: Color] = [:]
    @Published var swipeSelection: Int = 1

    private let calendar = Calendar.current

    init() {
        generateDays()
    }

    func generateDays() {
        days = CalendarGenerator.generateDaysInMonth(for: currentMonth, calendar: calendar)
    }

    func changeMonth(by offset: Int) {
        if let next = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = next
        }
    }

    func select(date: Date) {
        selectedDate = date
    }

    // 샘플 또는 실제 QWER/Todo 매핑 로직

    // 유틸 메서드
    func isSelected(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return calendar.isDate(d, inSameDayAs: selectedDate)
    }

    func isInCurrentMonth(_ date: Date?) -> Bool {
        guard let d = date else { return false }
        return calendar.isDate(d, equalTo: currentMonth, toGranularity: .month)
    }

    func eventColors(for date: Date) -> [Color] {
        let items: [ScheduleItem] = [] // to be replaced by ScheduleViewModel
        let members = Set(items.flatMap { $0.members })

        return QWERMember.allCases.compactMap { member in
            members.contains(member) ? memberColor(member) : nil
        }
    }
    
    func memberColor(_ member: QWERMember) -> Color {
        switch member {
        case .chodan: return .pastelChodan
        case .magenta: return .pastelMajenta
        case .hina: return .pastelHina
        case .siyo: return .pastelMing
        }
    }
    
    var numberOfWeeks: Int {
        return (days.count + 6) / 7
    }

    func cellHeight(for totalHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 240
        let adjustedHeight = max(totalHeight, minHeight)
        return adjustedHeight / CGFloat(numberOfWeeks)
    }
}
