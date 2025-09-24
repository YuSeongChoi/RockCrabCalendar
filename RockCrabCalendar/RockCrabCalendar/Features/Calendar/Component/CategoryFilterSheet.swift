//
//  CategoryFilterSheet.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/24/25.
//

import SwiftUI

struct CategoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<ScheduleCategory>
    let onApply: (Set<ScheduleCategory>) -> Void

    init(active: Set<ScheduleCategory>,
         onApply: @escaping (Set<ScheduleCategory>) -> Void) {
        _selected = State(initialValue: active)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // 전체 선택 (토글)
                    Button {
                        if selected.count == ScheduleCategory.allCases.count {
                            selected.removeAll()
                        } else {
                            selected = Set(ScheduleCategory.allCases)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            let allSelected = selected.count == ScheduleCategory.allCases.count
                            Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(allSelected ? .blue : .secondary)
                            Text("전체 선택")
                            Spacer()
                        }
                    }
                    
                    ForEach(Array(ScheduleCategory.allCases), id: \.self) { cat in
                        HStack(spacing: 10) {
                            Image(systemName: selected.contains(cat) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(cat) ? .blue : .secondary)
                            Text(cat.rawValue)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selected.contains(cat) { selected.remove(cat) }
                            else { selected.insert(cat) }
                        }
                    }
                } header: {
                    HStack {
                        Text("분류 선택")
                        Spacer()
                    }
                    .pretendSemiBold(size: 20)
                    .foregroundStyle(.primary)
                }
                .headerProminence(.increased)
            }
            .pretendSemiBold(size: 16)
            .foregroundStyle(.secondary)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
            }))
            .listRowBackground(Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
            }))
            .navigationTitle("필터")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onApply(selected)
                        dismiss()
                    } label: {
                        Text("적용")
                            .pretendSemiBold(size: 15)
                    }
                }
            }
            .toolbarBackground(Color(UIColor { trait in
                trait.userInterfaceStyle == .dark ? .black : .white
            }), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }))
    }
}
