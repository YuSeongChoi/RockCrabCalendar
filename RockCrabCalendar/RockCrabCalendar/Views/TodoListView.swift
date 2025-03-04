//
//  TodoListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2/27/25.
//

import SwiftUI

struct TodoListView: View {
    @Binding var todos: [TodoItem]
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("To-Do List")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            List {
                ForEach(todos.indices, id: \.self) { index in
                    HStack {
                        Button {
                            todos[index].isComplted.toggle()
                        } label: {
                            Image(systemName: todos[index].isComplted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todos[index].isComplted ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                        
                        Text(todos[index].title)
                            .strikethrough(todos[index].isComplted, color: .gray)
                            .foregroundStyle(todos[index].isComplted ? .gray : .black)
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}
