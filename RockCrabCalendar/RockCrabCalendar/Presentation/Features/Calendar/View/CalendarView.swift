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
    
    @State private var dragOffset: CGFloat = 0
    @State private var editTarget: ScheduleEditView.Mode? = nil
    
    private let lastSyncFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = AppDateFormats.lastSync
        return f
    }()
    private var lastSyncText: String {
        if let dt = scheduleVM.lastFetchedAt {
            return "최근 동기화: \(lastSyncFormatter.string(from: dt))"
        } else {
            return "최근 동기화 기록 없음"
        }
    }
    
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
                    
                    // 최근 동기화 캡션
                    Text(lastSyncText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 4)
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
                                        memberColor: scheduleVM.memberColor,
                                        onEdit: { item in
                                            editTarget = .editQWER(item)
                                        },
                                        embedInScrollView: false
                                    )
                                        .padding(.top, 12)
                                }
                                if !selectedUser.isEmpty {
                                    UserScheduleListView(
                                        schedules: selectedUser,
                                        onEdit: { item in
                                            if let latest = userVM.schedules.first(where: { $0.id == item.id }) {
                                                editTarget = .editUser(latest)
                                            } else {
                                                editTarget = .editUser(item)
                                            }
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
                .background(Color.appBackground)
            }
        }
        .navigationDestination(item: Binding(
            get: { editTarget },
            set: { editTarget = $0 }
        )) { mode in
            ScheduleEditView(
                mode: mode,
                defaultDate: scheduleVM.selectedDate,
                qwerVM: scheduleVM,
                userVM: userVM,
                defaultColor: {
                    if case .editUser(let item) = mode {
                        return Color(hex: item.colorHex)
                    } else {
                        return .purple
                    }
                }()
            )
        }
    }
    
    private func combinedEventColors(for date: Date) -> [Color] {
        var colors = scheduleVM.eventColors(for: date)
        let items = userVM.schedules(on: date)
        colors.append(contentsOf: items.map { Color(hex: $0.colorHex) })
        return colors
    }
}
