//
//  QWERScheduleListView.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct QWERScheduleListView: View {
    let schedules: [QWERScheduleItem]
    let memberColor: (QWERMember) -> Color
    let onEdit: (QWERScheduleItem) -> Void
    let embedInScrollView: Bool

    init(
        schedules: [QWERScheduleItem],
        memberColor: @escaping (QWERMember) -> Color,
        onEdit: @escaping (QWERScheduleItem) -> Void,
        embedInScrollView: Bool = true
    ) {
        self.schedules = schedules
        self.memberColor = memberColor
        self.onEdit = onEdit
        self.embedInScrollView = embedInScrollView
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                QWERScheduleCard(
                    item: item,
                    memberColor: memberColor,
                    onTap: { onEdit(item) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .transition(.opacity)

        if embedInScrollView {
            ScrollView { content }
                .scrollIndicators(.hidden)
        } else {
            content
        }
    }
}
