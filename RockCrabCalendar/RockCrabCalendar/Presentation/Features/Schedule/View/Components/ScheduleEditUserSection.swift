//
//  ScheduleEditUserSection.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct ScheduleEditUserSection: View {
    @Binding var isRepeat: Bool
    @Binding var repeatType: UserScheduleItem.RepeatType
    @Binding var repeatEndDate: Date
    @Binding var selectedColor: Color
    let rowBackground: Color

    var body: some View {
        Section("반복") {
            Toggle("반복", isOn: $isRepeat)
                .onChange(of: isRepeat) { _, newValue in
                    if newValue && repeatType == .none {
                        repeatType = .week
                    }
                }

            if isRepeat {
                Picker("반복 종류", selection: $repeatType) {
                    ForEach(UserScheduleItem.RepeatType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                DatePicker("반복 종료", selection: $repeatEndDate, displayedComponents: .date)
            }
        }
        .listRowBackground(rowBackground)

        Section("색상") {
            ColorPicker("색상 선택", selection: $selectedColor, supportsOpacity: false)
        }
        .listRowBackground(rowBackground)
    }
}
