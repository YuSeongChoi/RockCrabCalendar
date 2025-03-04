//
//  TodoManager.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2/27/25.
//

import Foundation

@MainActor
final class TodoManager: ObservableObject {
    @Published var todos: [String: [TodoItem]] = [:]
    
    init() {
        loadTodos()
    }
    
    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "todos"),
           let savedTodos = try? JSONDecoder().decode([String: [TodoItem]].self, from: data) {
            self.todos = savedTodos
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "todos")
        }
    }
    
    func addTodo(_ todo: TodoItem, for date: Date) {
        let dateString = date.string(format: "yyyy-MM-dd")
        if todos[dateString] == nil {
            todos[dateString] = []
        }
        todos[dateString]?.append(todo)
        saveTodos()
    }
    
    func deleteTodo(_ todo: TodoItem, for date: Date) {
        let dateString = date.string(format: "yyyy-MM-dd")
        if let index = todos[dateString]?.firstIndex(where: { $0.id == todo.id }) {
            todos[dateString]?.remove(at: index)
            saveTodos()
        }
    }
    
    func toggleCompletion(of todo: TodoItem, for date: Date) {
        let dateString = date.string(format: "yyyy-MM-dd")
        if let index = todos[dateString]?.firstIndex(where: { $0.id == todo.id}) {
            todos[dateString]?[index].isComplted.toggle()
            saveTodos()
        }
    }
}
