//
//  CalendarView.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI

/*
struct CalendarView: View {
    @StateObject private var calendarManager:CalendarManager
    @StateObject private var todoManager = TodoManager()
    @State private var onSelectedDate: Date?
    
    init(date: Date = Date()) {
        self._calendarManager = .init(wrappedValue: .init(date: date))
    }
    
    var today: Date {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return Calendar.current.date(from: components)!
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            scrollableCalendarView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 1)
        // 좌우 제스처
        .gesture(DragGesture()
            .onEnded { value in
                if value.translation.width < 0 {
                    calendarManager.changeMonth(by: 1)
                } else if value.translation.width > 0 {
                    calendarManager.changeMonth(by: -1)
                }
            }
        )
        // 상하 제스처
        .gesture(DragGesture()
            .onEnded { value in
                if value.translation.height < 0 {
                    calendarManager.changeMonth(by: 1)
                } else if value.translation.height > 0 {
                    calendarManager.changeMonth(by: -1)
                }
            }
        )
    }
    
    // MARK: - 헤더 뷰
    @ViewBuilder
    private var headerView: some View {
        VStack {
            HStack {
                yearMonthView
                Spacer()
                Button {
                    // TODO: 일정 추가
                    addTodoForSelectedDate()
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(.black)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 5)
            
            HStack {
                ForEach(Date.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .pretendBold(size: 13)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    // MARK: 연월 표시 뷰
    @ViewBuilder
    private var yearMonthView: some View {
        Text(calendarManager.currentDate, formatter: Date.calendarHeaderDateFormatter)
            .font(.title.bold())
            .foregroundStyle(.black)
    }
    
    // MARK: 캘린더 뷰
    @ViewBuilder
    private var scrollableCalendarView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 5) {
                calendarGridView
                
                
                
                if let selectedDate = onSelectedDate, let todos = todoManager.todos[selectedDate.string(format: "yyyy.MM.dd")] {
                    TodoListView(todos: Binding(
                        get: { todos },
                        set: { newTodos in todoManager.todos[selectedDate.string(format: "yyyy.MM.dd")] = newTodos }
                    )) { indexSet in
                        for index in indexSet {
                            todoManager.delete(date: selectedDate.string(format: "yyyy.MM.dd"), id: todos[index].id)
                        }
                    } onAdd: {
                        addTodoForSelectedDate()
                    }
                }
            }
            .padding(.top, 10)
        }
        .scrollIndicators(.hidden)
    }
    
    private func addTodoForSelectedDate() {
        let selectedDate = onSelectedDate ?? Date()
        let newTodo = TodoItem(title: "New Task", isComplted: false)
        todoManager.addTodo(date: selectedDate.string(format: "yyyy.MM.dd"), todo: newTodo)
    }
    
    private var calendarGridView: some View {
        /// 해당월에 존재하는 일자 수
        let daysInMonth: Int = calendarManager.numberOfDays(in: calendarManager.currentDate)
        /// 해당월의 첫 날짜가 갖는 요일
        let firstWeekday: Int = calendarManager.firstWeekdayOfMonth(in: calendarManager.currentDate) - 1
        /// 지난달 일자 수
        let lastDayOfMonthBefore: Int = calendarManager.numberOfDays(in: calendarManager.previousMonth())
        
        /// 해당월의 주차 수
        let numberOfRows: Int = Int(ceil(Double(daysInMonth + firstWeekday) / 7.0))
        /// 보여지는 일수
        let visibleDaysOfNextMonth: Int = numberOfRows * 7 - (daysInMonth + firstWeekday)
        
        return LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
            ForEach(-firstWeekday..<daysInMonth + visibleDaysOfNextMonth, id: \.self) { index in
                Group {
                    if index > -1 && index < daysInMonth {
                        let date = calendarManager.getDate(for: index)
                        let day = Calendar.current.component(.day, from: date)
                        let clicked = onSelectedDate == date
                        let isToday = date.formattedCalendarDayDate == today.formattedCalendarDayDate
                        CalendarCellView(day: day, clicked: clicked, isToday: isToday)
                    } else if let prevMonthData = Calendar.current.date(
                        byAdding: .day,
                        value: index + lastDayOfMonthBefore,
                        to: calendarManager.previousMonth()) {
                        let day = Calendar.current.component(.day, from: prevMonthData)
                        CalendarCellView(day: day, isCurrentMonthDay: false)
                    }
                }
                .background(Color.white)
                .onTapGesture {
                    if 0 <= index && index < daysInMonth {
                        let date = calendarManager.getDate(for: index)
                        onSelectedDate = date
                    }
                }
            }
        }
    }
    
}

*/
