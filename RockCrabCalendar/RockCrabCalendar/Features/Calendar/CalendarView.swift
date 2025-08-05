//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var calendarVM = CalendarViewModel()
    @StateObject private var scheduleVM = ScheduleViewModel()
    @State private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    dateSelectionView
                    dateHeaderView
                    dateGridView(height: geometry.size.height * 0.5)
                    Divider()
                }
                .background(Color(.secondarySystemBackground))
                
                let selectedDateSchedules = scheduleVM.schedules.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: scheduleVM.selectedDate)
                }

                if !selectedDateSchedules.isEmpty {
                    scheduleListView(schedules: selectedDateSchedules)
                    Spacer()
                } else {
                    Spacer()
                    Text("일정이 없습니다!")
                        .pretendSemiBold(size: 18)
                        .foregroundStyle(Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .RGB_168 }))
                    Spacer()
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.fetchAllSchedules()
        }
    }
    
    // MARK: 월 선택뷰
    @ViewBuilder
    private var dateSelectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    calendarVM.changeMonth(by: -1)
                    calendarVM.select(date: calendarVM.selectedDate)
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
                    calendarVM.select(date: calendarVM.selectedDate)
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
        HStack {
            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(index == 0 ? Color.red : index == 6 ? Color.blue : .primary)
                    .pretendBold(size: 16)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: 요일 그리드 뷰
    private func dateGridView(height: CGFloat) -> some View {
        VStack {
            let numberOfWeeks = CGFloat(calendarVM.numberOfWeeks)
            let cellHeight = calendarVM.cellHeight(for: height)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
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
            .frame(height: cellHeight * numberOfWeeks)
        }
        .gesture(
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
                                
                                ForEach(item.members, id: \.self) { member in
                                    Text(member.name)
                                        .pretendReg(size: 13)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule().fill(calendarVM.memberColor(member))
                                        )
                                        .foregroundColor(.black)
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
