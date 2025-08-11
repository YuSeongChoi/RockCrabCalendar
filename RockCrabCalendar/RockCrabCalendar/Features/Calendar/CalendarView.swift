//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var calendarVM = CalendarViewModel()
    @State private var scheduleVM = ScheduleViewModel()
    @State private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    dateSelectionView
                    // TODO: 신규 버튼기능
                    HStack {
                        Button {
                            let today = Date()
                            calendarVM.select(date: today)
                            calendarVM.currentMonth = calendarVM.startOfMonth(for: today)
                            scheduleVM.selectedDate = today
                        } label: {
                            Label("오늘", systemImage: "clock.arrow.circlepath")
                                .labelStyle(.titleAndIcon)
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(UIColor.systemGray5)))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Button {
                            scheduleVM.fetchAllSchedules(force: true)
                        } label: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(6)
                                .background(Capsule().fill(Color(UIColor.systemGray5)))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)

                    // 최근 동기화 캡션
                    Text("최근 동기화 \(scheduleVM.lastSyncText)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    dateHeaderView
                    dateGridView(height: geometry.size.height * 0.5)
                    Divider()
                }
                .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white }))
                
                let selectedDateSchedules = scheduleVM.schedules.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: scheduleVM.selectedDate)
                }

                if !selectedDateSchedules.isEmpty {
                    scheduleListView(schedules: selectedDateSchedules)
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                        Text("일정이 없습니다")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white }))
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.fetchAllSchedules(force: false)
        }
    }
    
    // MARK: 월 선택뷰
    @ViewBuilder
    private var dateSelectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    calendarVM.changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                
                Text(monthYearFormatter.string(from: calendarVM.currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                Button {
                    calendarVM.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            .foregroundStyle(.primary)
            
            Divider()
        }
    }
    
    // MARK: 요일 헤더 뷰
    @ViewBuilder
    private var dateHeaderView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                let color: Color = {
                    if index == 0 { return Color.red.opacity(0.85) }
                    if index == 6 { return Color.blue.opacity(0.85) }
                    return .secondary
                }()
                Text(day)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
    
    // MARK: 요일 그리드 뷰
    private func dateGridView(height: CGFloat) -> some View {
        VStack {
            let numberOfWeeks = CGFloat(calendarVM.numberOfWeeks)
            let cellHeight = calendarVM.cellHeight(for: height)
            
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(calendarVM.days.enumerated()), id: \.offset) { index, date in
                    CalendarDayCell(
                        date: date,
                        isSelected: calendarVM.isSelected(date),
                        isInCurrentMonth: calendarVM.isInCurrentMonth(date),
                        eventColors: scheduleVM.eventColors(for: date)
                    )
                    .frame(height: cellHeight)
                    .onTapGesture {
                        withAnimation {
                            calendarVM.select(date: date)
                            scheduleVM.selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: cellHeight * numberOfWeeks)
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in dragOffset = value.translation.width }
                .onEnded { value in
                    if value.translation.width < -50 {
                        calendarVM.changeMonth(by: 1)
                    } else if value.translation.width > 50 {
                        calendarVM.changeMonth(by: -1)
                    }
                    dragOffset = 0
                }
        )
    }
    
    // MARK: 스케줄 리스트 뷰
    @ViewBuilder
    private func scheduleListView(schedules: [ScheduleItem]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(schedules, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .pretendSemiBold(size: 16)
                        
                        HStack(spacing: 8) {
                            if !item.time.isEmpty {
                                Label(item.time, systemImage: "clock")
                            }
                            if !item.place.isEmpty {
                                Label(item.place, systemImage: "house.circle.fill")
                            }
                        }
                        .pretendReg(size: 13)
                        .foregroundColor(.gray)
                        
                        if !item.members.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: item.members.count == 1 ? "person.fill" : "person.3.fill")
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 8) {
                                    ForEach(item.members, id: \.self) { member in
                                        Text(member.name)
                                            .pretendReg(size: 13)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule().fill(scheduleVM.memberColor(member))
                                            )
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.vertical)
            .transition(.opacity)
        }
        .scrollIndicators(.hidden)
    }
}
