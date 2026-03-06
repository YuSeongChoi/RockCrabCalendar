//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI
import RockCrabShared
import RockCrabDomain

struct CalendarView: View {
    var calendarVM: CalendarViewModel
    var scheduleVM: QWERScheduleViewModel
    var userVM: UserScheduleViewModel
    let onEdit: (ScheduleEditMode) -> Void
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    CalendarWeekdayHeaderView()
                        CalendarMonthGridView(
                            days: calendarVM.days,
                            numberOfWeeks: calendarVM.numberOfWeeks,
                            availableWidth: geometry.size.width,
                            isSelected: { calendarVM.isSelected($0) },
                            isInCurrentMonth: { calendarVM.isInCurrentMonth($0) },
                            eventColors: combinedEventColors,
                            holidayName: { calendarVM.holidayName(on: $0) },
                            onSelectDate: { date in
                                calendarVM.select(date: date)
                                scheduleVM.selectedDate = date
                            },
                        onChangeMonth: { offset in
                            calendarVM.changeMonth(by: offset)
                        },
                        dragOffset: $dragOffset
                    )
                    
                    Divider()
                }
                
                ZStack {
                    let selectedQWER = scheduleVM.schedules(on: scheduleVM.selectedDate)
                    let selectedUser = userVM.schedules(on: scheduleVM.selectedDate)
                    if !selectedQWER.isEmpty || !selectedUser.isEmpty {
                        ScrollView {
                            VStack(spacing: 16) {
                                if !selectedQWER.isEmpty {
                                    QWERScheduleListView(
                                        schedules: selectedQWER,
                                        memberColor: QWERStyleMapper.memberColor,
                                        onEdit: { item in
                                            onEdit(.editQWER(item))
                                        },
                                        embedInScrollView: false
                                    )
                                        .padding(.top, 12)
                                }
                                if !selectedUser.isEmpty {
                                    UserScheduleListView(
                                        schedules: selectedUser,
                                        onEdit: { item in
                                            onEdit(.editUser(userVM.latestSchedule(for: item)))
                                        },
                                        embedInScrollView: false
                                    )
                                        .padding(.top, selectedQWER.isEmpty ? 12 : 0)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        Spacer()
                        EmptyStateView(
                            systemImage: "calendar.badge.exclamationmark",
                            title: "일정이 없습니다"
                        )
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.appBackground)
    }
    
    private func combinedEventColors(for date: Date) -> [Color] {
        var colors = qwerEventColors(for: date)
        let items = userVM.schedules(on: date)
        colors.append(contentsOf: items.map { Color(hex: $0.colorHex) })
        return colors
    }

    private func qwerEventColors(for date: Date) -> [Color] {
        let items = scheduleVM.schedules(on: date)
        let members = Set(items.flatMap { $0.members })
        return QWERMember.allCases.compactMap { member in
            members.contains(member) ? QWERStyleMapper.memberColor(member) : nil
        }
    }
}
