//
//  ScheduleListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 11/27/25.
//

import SwiftUI
import RockCrabShared
import RockCrabDomain

struct ScheduleListView: View {
    var calendarVM: CalendarViewModel
    var scheduleVM: QWERScheduleViewModel
    var userVM: UserScheduleViewModel
    let onEdit: (ScheduleEditMode) -> Void
    
    private let calendar = Calendar.current
    
    private let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.dateFormat = AppDateFormats.dayLabel
        return f
    }()
    private var monthRange: DateInterval {
        calendarVM.currentMonthRange()
    }
    
    var body: some View {
        Group {
            let qwerMonth = monthSchedulesForCurrentMonth()
            let userMonth = monthUserSchedulesForCurrentMonth()
            if qwerMonth.isEmpty && userMonth.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.exclamationmark",
                    title: "이번 달 일정이 없습니다"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                let groupedQ = Dictionary(grouping: qwerMonth) { calendar.startOfDay(for: $0.date) }
                let groupedU = Dictionary(grouping: userMonth) { calendar.startOfDay(for: $0.date) }
                let days = Set(groupedQ.keys).union(groupedU.keys).sorted()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(days, id: \.self) { day in
                            ScheduleDayHeaderView(
                                day: day,
                                formatter: dayLabelFormatter,
                                holidayName: calendarVM.holidayName(on: day)
                            )
                            
                            if let qItems = groupedQ[day] {
                                QWERScheduleListView(
                                    schedules: qItems,
                                    memberColor: QWERStyleMapper.memberColor,
                                    onEdit: { item in
                                        onEdit(.editQWER(item))
                                    }
                                )
                            }
                            if let uItems = groupedU[day] {
                                UserScheduleListView(
                                    schedules: uItems,
                                    onEdit: { item in
                                        onEdit(.editUser(userVM.latestSchedule(for: item)))
                                    }
                                )
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    private func monthSchedulesForCurrentMonth() -> [QWERScheduleItem] {
        scheduleVM.schedules(in: monthRange)
    }
    
    private func monthUserSchedulesForCurrentMonth() -> [UserScheduleItem] {
        userVM.schedules(in: monthRange)
    }
}
