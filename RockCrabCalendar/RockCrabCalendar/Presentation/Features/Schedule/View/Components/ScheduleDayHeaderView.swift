//
//  ScheduleDayHeaderView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI

struct ScheduleDayHeaderView: View {
    let day: Date
    let formatter: DateFormatter
    let holidayName: String?

    var body: some View {
        HStack(spacing: 6) {
            Text(formatter.string(from: day))
                .pretendSemiBold(size: 16)
                .foregroundStyle(.secondary)
            if let holidayName {
                Text(holidayName)
                    .pretendSemiBold(size: 13)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
    }
}
