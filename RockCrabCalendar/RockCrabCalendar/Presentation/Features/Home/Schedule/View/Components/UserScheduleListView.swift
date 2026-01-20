//
//  UserScheduleListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct UserScheduleListView: View {
    let schedules: [UserScheduleItem]
    let onEdit: (UserScheduleItem) -> Void
    let embedInScrollView: Bool

    init(
        schedules: [UserScheduleItem],
        onEdit: @escaping (UserScheduleItem) -> Void,
        embedInScrollView: Bool = true
    ) {
        self.schedules = schedules
        self.onEdit = onEdit
        self.embedInScrollView = embedInScrollView
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                UserScheduleCard(item: item, onTap: { onEdit(item) })
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
