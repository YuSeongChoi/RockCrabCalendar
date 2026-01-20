//
//  HomeDateSelectionView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabShared

struct HomeDateSelectionView: View {
    let currentMonth: Date
    let onPrev: () -> Void
    let onNext: () -> Void

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = AppDateFormats.monthTitle
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onPrev) {
                    Image(systemName: "chevron.left")
                }
                Spacer()

                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            .foregroundStyle(.primary)

            Divider()
        }
    }
}
