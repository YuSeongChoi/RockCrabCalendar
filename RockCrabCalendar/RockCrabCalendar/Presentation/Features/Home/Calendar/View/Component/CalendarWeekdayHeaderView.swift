//
//  CalendarWeekdayHeaderView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabShared

struct CalendarWeekdayHeaderView: View {
    private let daysOfWeek = AppDateFormatterFactory.veryShortWeekdaySymbols()
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                let color: Color = {
                    if index == 0 { return Color.red.opacity(0.85) }
                    if index == 6 { return Color.blue.opacity(0.85) }
                    return .secondary
                }()
                Text(day)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(.bottom, 15)
    }
}
