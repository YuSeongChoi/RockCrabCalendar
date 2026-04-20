//
//  ScheduleEditBasicInfoSection.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabDomain
import RockCrabShared

struct ScheduleEditBasicInfoSection: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var isAllDay: Bool
    @Binding var startTime: Date?
    @Binding var endTime: Date?
    var qwerTimeStatus: Binding<QWERScheduleItem.TimeStatus>?
    @Binding var shouldNotify: Bool
    @Binding var notificationLeadTime: NotificationLeadTime
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
                .datePickerStyle(.compact)

            if let qwerTimeStatus {
                Picker("시간", selection: qwerTimeStatus) {
                    Text("하루종일").tag(QWERScheduleItem.TimeStatus.allDay)
                    Text("시간 있음").tag(QWERScheduleItem.TimeStatus.timed)
                    Text("시간 미정").tag(QWERScheduleItem.TimeStatus.unspecified)
                }
                .pickerStyle(.segmented)

                if qwerTimeStatus.wrappedValue == .timed {
                    DatePicker("시작 시간", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                    DatePicker("종료 시간", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                    Toggle("시작 전에 알림 받기", isOn: $shouldNotify)
                    if shouldNotify {
                        notificationLeadTimeMenu
                    }
                }
            } else {
                Toggle("하루종일", isOn: $isAllDay)

                if !isAllDay {
                    DatePicker("시작 시간", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                    DatePicker("종료 시간", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                    Toggle("시작 전에 알림 받기", isOn: $shouldNotify)
                    if shouldNotify {
                        notificationLeadTimeMenu
                    }
                }
            }

            TextField("장소", text: $place)
        }
        .listRowBackground(rowBackground)
        .onChange(of: qwerTimeStatus?.wrappedValue) { _, newValue in
            guard let newValue else { return }
            switch newValue {
            case .allDay:
                isAllDay = true
                startTime = nil
                endTime = nil
                shouldNotify = false
            case .timed:
                isAllDay = false
                startTime = startTime ?? defaultStartTime()
            case .unspecified:
                isAllDay = false
                startTime = nil
                endTime = nil
                shouldNotify = false
            }
        }
        .onChange(of: isAllDay) { _, newValue in
            guard qwerTimeStatus == nil else { return }
            if newValue {
                startTime = nil
                endTime = nil
                shouldNotify = false
            } else {
                startTime = startTime ?? defaultStartTime()
                endTime = endTime ?? defaultEndTime()
            }
        }
        .task(id: startTime) {
            guard qwerTimeStatus == nil else { return }
            guard let newStart = startTime else { return }

            if endTime == nil || endTime! <= newStart {
                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStart)
            }
        }
    }

    @ViewBuilder
    private var notificationLeadTimeMenu: some View {
        Menu {
            Picker("알림 시간", selection: $notificationLeadTime) {
                ForEach(NotificationLeadTime.allCases) { leadTime in
                    Text(leadTime.displayText).tag(leadTime)
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("알림 시간")
                        .foregroundStyle(Color.textColor)
                    Text(notificationLeadTime.displayText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.textColor)
        }
    }
}
