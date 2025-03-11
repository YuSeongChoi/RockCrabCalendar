//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var todoManager = TodoManager()
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var newTodoTitle = ""
    @State private var dragOffset: CGFloat = 0
    
    private let calendar = Calendar.current
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.headline)
                Spacer()
                Button {
                    changeMonth(by: 1)
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
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(generateDaysInMonth(for: currentMonth), id: \.self) { date in
                    if let date = date {
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        Text("\(calendar.component(.day, from: date))")
                            .frame(width: 40, height: 40)
                            .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .foregroundColor(isCurrentMonth ? .primary : .gray)
                            .onTapGesture {
                                selectedDate = date
                            }
                    } else {
                        Color.clear.frame(width: 40, height: 40)
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
                            changeMonth(by: 1)
                        } else if value.translation.width > 50 {
                            changeMonth(by: -1)
                        }
                        dragOffset = 0
                    }
            )
            
            // Todo 리스트와 추가 버튼
            VStack {
                Text("할 일 목록")
                    .font(.headline)
                    .padding(.top)
                
                let dateString = selectedDate.string(format: "yyyy-MM-dd")
                if let todos = todoManager.todos[dateString], !todos.isEmpty {
                    List {
                        ForEach(todos) { todo in
                            HStack {
                                Button {
                                    todoManager.toggleCompletion(of: todo, for: selectedDate)
                                } label: {
                                    Image(systemName: todo.isComplted ? "checkmark.circle.fill" : "circle")
                                }
                                
                                Text(todo.title)
                                    .strikethrough(todo.isComplted)
                                    .foregroundStyle(todo.isComplted ? .gray : .primary)
                            }
                        }
                        .onDelete(perform: deleteTodo)
                    }
                    .frame(maxHeight: 200)
                } else {
                    Text("할 일이 없습니다.")
                        .padding()
                }
                
                HStack {
                    TextField("새 할 일", text: $newTodoTitle)
                        .textFieldStyle(.roundedBorder)
                    Button(action: addTodo) {
                        Image(systemName: "plus")
                    }
                    .disabled(newTodoTitle.isEmpty)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    // 월 변경 함수
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // 해당 월의 날짜 배열 생성
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        
        // 현재 월의 첫날과 마지막 날
        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = monthInterval.end.addingTimeInterval(-1)
        
        // 첫날의 요일 (일요일: 1 ~ 토요일 : 7)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 그리드 시작 날짜 (첫째 주 일요일)
        let startDate = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: firstDayOfMonth)!
        
        // 마지막 날의 요일
        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        
        // 필요한 총 날짜 수 계산
        let daysInMonth = calendar.component(.day, from: lastDayOfMonth)
        let totalDaysNeeded = (firstWeekday - 1) + daysInMonth + (7 - lastWeekday)
        
        // 필요한 주 수 계산 (5주 또는 6주)
        let weeksNeeded = (totalDaysNeeded <= 35) ? 5 : 6
        
        // 날짜 배열 생성
        var days: [Date?] = []
        for i in 0..<(weeksNeeded * 7) {
            let currentDate = calendar.date(byAdding: .day, value: i, to: startDate)!
            days.append(currentDate)
        }
        return days
    }
    
    private func addTodo() {
        let newTodo = TodoItem(title: newTodoTitle)
        todoManager.addTodo(newTodo, for: selectedDate)
        newTodoTitle = ""
    }
    
    private func deleteTodo(at offsets: IndexSet) {
        let dateString = selectedDate.string(format: "yyyy-MM-dd")
        if let todos = todoManager.todos[dateString] {
            for index in offsets {
                let todo = todos[index]
                todoManager.deleteTodo(todo, for: selectedDate)
            }
        }
    }
}
