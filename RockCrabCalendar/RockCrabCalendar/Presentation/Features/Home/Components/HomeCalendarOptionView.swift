//
//  HomeCalendarOptionView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI

struct HomeCalendarOptionView: View {
    let viewType: HomeMainView.ViewType
    let onShowFilter: () -> Void
    let onToday: () -> Void
    let onToggleView: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Button(action: onShowFilter) {
                    Label("필터", systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.titleAndIcon)
                        .pretendSemiBold(size: 14)
                        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .background(Capsule().fill(Color.pillBackground))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            Button(action: onToday) {
                Text("오늘")
                    .pretendSemiBold(size: 14)
                    .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .background(Capsule().fill(Color.pillBackground))
                    .foregroundColor(.primary)
            }

            HStack {
                Spacer()
                Button(action: onToggleView) {
                    Image(systemName: viewType == .calendar ? "list.bullet" : "calendar")
                }
                .pretendSemiBold(size: 14)
                .padding(6)
                .animation(.easeInOut(duration: 0.25), value: viewType)
                .background(Capsule().fill(Color.pillBackground))
                .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
    }
}
