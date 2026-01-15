//
//  CategoryFilterSheet.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/24/25.
//

import SwiftUI
import RockCrabDomain

struct CategoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
                    CategorySelectAllRow(
                        isAllSelected: selected.count == ScheduleCategory.allCases.count,
                        onToggle: toggleAll
                    )

                    ForEach(Array(ScheduleCategory.allCases), id: \.self) { cat in
                        CategoryFilterRow(
                            title: cat.rawValue,
                            isSelected: selected.contains(cat),
                            onToggle: { toggleCategory(cat) }
                        )
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(closeButtonColor)
                    }
                }
                
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
    
    private var closeButtonColor: Color {
        switch colorScheme {
        case .light:
            return Color.black  // 밝은 모드에서는 검은색 또는 어두운 계열
        case .dark:
            return Color.white  // 다크 모드에서는 흰색 또는 밝은 계열
        @unknown default:
            return Color.primary
        }
    }

    private func toggleAll() {
        if selected.count == ScheduleCategory.allCases.count {
            selected.removeAll()
        } else {
            selected = Set(ScheduleCategory.allCases)
        }
    }

    private func toggleCategory(_ category: ScheduleCategory) {
        if selected.contains(category) {
            selected.remove(category)
        } else {
            selected.insert(category)
        }
    }
}

private struct CategorySelectAllRow: View {
    let isAllSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isAllSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAllSelected ? .blue : .secondary)
                Text("전체 선택")
                Spacer()
            }
        }
    }
}

private struct CategoryFilterRow: View {
    let title: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
            Text(title)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}
