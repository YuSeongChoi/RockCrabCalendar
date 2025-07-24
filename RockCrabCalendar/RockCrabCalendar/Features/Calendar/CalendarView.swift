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
        VStack {
            VStack {
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
                
                // 요일 헤더
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                    }
                }
                .padding(.bottom, 8)
                
                // 날짜 그리드
                LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 44), spacing: 8), count: 7), spacing: 12) {
                    ForEach(Array(viewModel.days.enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            CalendarDayCell(
                                date: date,
                                isSelected: viewModel.isSelected(date),
                                isInCurrentMonth: viewModel.isInCurrentMonth(date),
                                eventColors: viewModel.eventColors(for: date)
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .onTapGesture {
                                viewModel.select(date: date)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.05))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
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
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.calendarBackground.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 10)
    }
}
