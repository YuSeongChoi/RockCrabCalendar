//
//  HomeCalendarOptionView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI

struct HomeCalendarOptionView: View {
    let viewType: HomeMainView.ViewType
    let onShowFilter: () -> Void
    let onToday: () -> Void
    let onToggleView: () -> Void
    let onRefresh: () -> Void

    var body: some View {
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
            Button(action: onToday) {
                Text("오늘")
                    .pretendSemiBold(size: 14)
                    .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .background(Capsule().fill(Color.pillBackground))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: onToggleView) {
                Image(systemName: viewType == .calendar ? "list.bullet" : "calendar")
            }
            .pretendSemiBold(size: 14)
            .padding(6)
            .animation(.easeInOut(duration: 0.25), value: viewType)
            .background(Capsule().fill(Color.pillBackground))
            .foregroundColor(.primary)

            Button(action: onRefresh) {
                Image(systemName: "arrow.circlepath")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color.pillBackground))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
    }
}
