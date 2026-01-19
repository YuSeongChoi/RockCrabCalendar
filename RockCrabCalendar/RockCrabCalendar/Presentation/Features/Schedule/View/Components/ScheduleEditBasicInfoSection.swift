//
//  ScheduleEditBasicInfoSection.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import SwiftUI

struct ScheduleEditBasicInfoSection: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var isAllDay: Bool
    @Binding var startTime: Date?
    @Binding var endTime: Date?
    @Binding var shouldNotify: Bool
    @Binding var place: String

    let defaultStartTime: () -> Date
    let defaultEndTime: () -> Date
    let rowBackground: Color

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { startTime ?? defaultStartTime() },
            set: { startTime = $0 }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { endTime ?? defaultEndTime() },
            set: { endTime = $0 }
        )
    }

    var body: some View {
        Section("기본 정보") {
            TextField("제목", text: $title)
            DatePicker("날짜", selection: $date, displayedComponents: .date)
            Toggle("하루종일", isOn: $isAllDay)

            if !isAllDay {
                DatePicker("시작 시간", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                DatePicker("종료 시간", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                Toggle("시작 전에 알림 받기", isOn: $shouldNotify)
            }

            TextField("장소", text: $place)
        }
        .listRowBackground(rowBackground)
        .onChange(of: isAllDay) { _, newValue in
            if newValue {
                startTime = nil
                endTime = nil
            } else {
                startTime = startTime ?? defaultStartTime()
                endTime = endTime ?? defaultEndTime()
            }
        }
        .task(id: startTime) {
            guard let newStart = startTime else { return }

            if endTime == nil || endTime! <= newStart {
                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStart)
            }
        }
    }
}
