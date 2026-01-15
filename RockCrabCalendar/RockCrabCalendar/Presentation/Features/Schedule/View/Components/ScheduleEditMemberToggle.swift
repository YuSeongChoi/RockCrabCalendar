//
//  ScheduleEditMemberToggle.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct ScheduleEditMemberToggle: View {
    let member: QWERMember
    @Binding var isSelected: Bool
    let tintColor: Color

    var body: some View {
        Toggle(isOn: $isSelected) {
            HStack(spacing: 8) {
                Circle()
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                    .background(Circle().fill(tintColor))
                    .frame(width: 10, height: 10)

                Text(member.name)
            }
        }
        .tint(tintColor)
    }
}
