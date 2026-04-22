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
    let searchText: String
    let onEdit: (ScheduleEditMode) -> Void
    let onRecord: (ScheduleRecordTarget) -> Void
    
    private let calendar = Calendar.current
    
    private let dayLabelFormatter: DateFormatter = {
        AppDateFormatterFactory.dayLabelFormatter()
    }()
    private var monthRange: DateInterval {
        calendarVM.currentMonthRange()
    }

    private var searchAnimation: Animation {
        .easeInOut(duration: 0.18)
    }
    
    var body: some View {
        Group {
            let searchResult = ScheduleSearchMatcher.filter(
                qwerSchedules: monthSchedulesForCurrentMonth(),
                userSchedules: monthUserSchedulesForCurrentMonth(),
                query: searchText
            )
            let qwerMonth = searchResult.0
            let userMonth = searchResult.1
            if qwerMonth.isEmpty && userMonth.isEmpty {
                EmptyStateView(
                    systemImage: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass",
                    title: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "이번 달 일정이 없습니다" : "검색 결과가 없습니다"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .transition(.opacity)
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
                                    },
                                    onRecord: { item in
                                        onRecord(ScheduleRecordTarget(qwerSchedule: item))
                                    }
                                )
                            }
                            if let uItems = groupedU[day] {
                                UserScheduleListView(
                                    schedules: uItems,
                                    onEdit: { item in
                                        onEdit(.editUser(userVM.latestSchedule(for: item)))
                                    },
                                    onRecord: { item in
                                        onRecord(ScheduleRecordTarget(userSchedule: userVM.latestSchedule(for: item)))
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
        .id(searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        .animation(searchAnimation, value: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
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
