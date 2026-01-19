//
//  ScheduleEditQWERSection.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct ScheduleEditQWERSection: View {
    let mode: ScheduleEditMode
    let isLocalOnly: Bool
    @Binding var category: ScheduleCategory
    @Binding var selectedMembers: Set<QWERMember>
    let memberColor: (QWERMember) -> Color
    let rowBackground: Color

    var body: some View {
        if case .editQWER = mode, !isLocalOnly {
            Section {
                Label {
                    Text("이 일정은 Firestore에 등록된 항목이라 앱에서 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제 가능합니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .listRowBackground(rowBackground)
        }

        Section("분류") {
            Picker("카테고리", selection: $category) {
                ForEach(ScheduleCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
        }
        .listRowBackground(rowBackground)

        Section("멤버") {
            ForEach(QWERMember.allCases, id: \.self) { member in
                let binding = Binding(
                    get: { selectedMembers.contains(member) },
                    set: { newValue in
                        if newValue { selectedMembers.insert(member) }
                        else { selectedMembers.remove(member) }
                    }
                )
                ScheduleEditMemberToggle(
                    member: member,
                    isSelected: binding,
                    tintColor: memberColor(member)
                )
            }
        }
        .listRowBackground(rowBackground)
    }
}
