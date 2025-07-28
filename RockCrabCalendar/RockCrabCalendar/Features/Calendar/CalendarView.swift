//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var todoManager = TodoManager()
    @StateObject private var viewModel = CalendarViewModel()
    @State private var newTodoTitle = ""
    @State private var dragOffset: CGFloat = 0
    
    @State private var showTodoSheet: Bool = false
    
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
            dateSelectionView
            dateHeaderView
            dateGridView(height: geometry.size.height * 0.5)
            Divider()
            if !viewModel.scheduleItems(for: viewModel.selectedDate).isEmpty {
                scheduleListView
                Spacer()
            } else {
                Spacer()
                Text("일정이 없습니다!")
                    .pretendSemiBold(size: 18)
                    .foregroundStyle(Color.RGB_168)
                Spacer()
            }
        }
        .background(.white)
    }
}
    
    // MARK: 월 선택뷰
    @ViewBuilder
    private var dateSelectionView: some View {
        HStack {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthYearFormatter.string(from: viewModel.currentMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .foregroundStyle(.black)
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
        let numberOfWeeks = CGFloat(viewModel.numberOfWeeks)
        let cellHeight = viewModel.cellHeight(for: height)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Array(viewModel.days.enumerated()), id: \.offset) { index, date in
                CalendarDayCell(
                    date: date,
                    isSelected: viewModel.isSelected(date),
                    isInCurrentMonth: viewModel.isInCurrentMonth(date),
                    eventColors: viewModel.eventColors(for: date)
                )
                .frame(height: cellHeight)
                .background(Color.white)
                .onTapGesture {
                    withAnimation {
                        viewModel.select(date: date)
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
                    viewModel.changeMonth(by: 1)
                } else if value.translation.width > 50 {
                    viewModel.changeMonth(by: -1)
                }
                dragOffset = 0
            }
    )
}
    
    // MARK: 스케줄 리스트 뷰
    @ViewBuilder
    private var scheduleListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.scheduleItems(for: viewModel.selectedDate), id: \.id) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))

                        HStack(spacing: 8) {
                            Label(item.time, systemImage: "clock")
                            Label(item.place, systemImage: "house.lodge.circle.fill")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                        if !item.members.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: item.members.count == 1 ? "person.fill" : "person.3.fill")
                                    .foregroundColor(.blue)
                                ForEach(item.members, id: \.self) { member in
                                    Text(member.rawValue.capitalized)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule().fill(viewModel.memberColor(member))
                                        )
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 248/255, green: 248/255, blue: 248/255))
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
