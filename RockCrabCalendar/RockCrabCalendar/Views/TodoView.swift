//
//  TodoView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/3/25.
//

import SwiftUI

struct TodoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var todoManager: TodoManager
    @State private var newTodoTitle: String = ""
    let selectedDate: Date
    
    var dateString: String {
        todoManager.dateFormatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack {
            Text(dateString)
                .pretendSemiBold(size: 18)
                .padding()
            
            List {
                if let todos = todoManager.todos[dateString], !todos.isEmpty {
                    ForEach(todos) { todo in
                        HStack {
                            Button {
                                todoManager.toggleCompletion(of: todo, for: selectedDate)
                            } label: {
                                Image(systemName: todo.isComplted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(todo.isComplted ? .gray : .blue)
                            }
                            Text(todo.title)
                                .strikethrough(todo.isComplted)
                                .foregroundStyle(todo.isComplted ? .gray : .primary)
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            let todo = todos[index]
                            todoManager.deleteTodo(todo, for: selectedDate)
                        }
                    }
                } else {
                    Text("할 일이 없습니다.")
                        .foregroundStyle(.gray)
                        .padding()
                }
            }
            
            // 새 할 일 입력
            
        }
    }
}
