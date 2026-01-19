//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ScheduleEditViewModel

    init(viewModel: ScheduleEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                ScheduleEditBasicInfoSection(
                    title: $viewModel.form.title,
                    date: $viewModel.form.date,
                    isAllDay: $viewModel.form.isAllDay,
                    startTime: $viewModel.form.startTime,
                    endTime: $viewModel.form.endTime,
                    shouldNotify: $viewModel.form.shouldNotify,
                    place: $viewModel.form.place,
                    defaultStartTime: defaultStartTime,
                    defaultEndTime: defaultEndTime
                )
                if viewModel.kind == .qwer {
                    ScheduleEditQWERSection(
                        mode: viewModel.mode,
                        isLocalOnly: viewModel.isQWERLocalSchedule,
                        category: $viewModel.form.category,
                        selectedMembers: $viewModel.form.selectedMembers,
                        memberColor: QWERStyleMapper.memberColor
                    )
                } else {
                    ScheduleEditUserSection(
                        isRepeat: $viewModel.form.isRepeat,
                        repeatType: $viewModel.form.repeatType,
                        repeatEndDate: $viewModel.form.repeatEndDate,
                        selectedColor: $viewModel.form.selectedColor
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .listRowBackground(listRowBackgroundColor)
            .background(listBackgroundColor)
            .navigationTitle(viewModel.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Text("저장")
                            .bold()
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if case .editQWER = viewModel.mode {
                        Button(role: .destructive) { deleteItem() } label: { Text("삭제") }
                    } else if case .editUser = viewModel.mode {
                        Button(role: .destructive) { deleteItem() } label: { Text("삭제") }
                    }
                }
            }
            .toolbarBackground(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? .black : .white
                }), for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("삭제할 수 없습니다", isPresented: $viewModel.showNonDeletableAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("Firestore에 올라간 QWER 일정은 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제할 수 있어요.")
            }
        }
        .environment(\.locale, Locale(identifier: "ko_KR"))
        .task {
            await viewModel.refreshLocalFlagIfNeeded()
        }
        .onAppear {
            AnalyticsHelper.logEvent(eventName: "schedule_edit_screen", parameters: ["label":"일정수정화면"])
        }
    }
}

// MARK: - Save
private extension ScheduleEditView {
    func save() {
        viewModel.save()

        dismiss()
    }
    
    func deleteItem() {
        if viewModel.deleteButtonTapped() {
            dismiss()
        }
    }
}

// MARK: - Sections
private extension ScheduleEditView {
    var listRowBackgroundColor: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
        })
    }

    var listBackgroundColor: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
        })
    }

    func defaultStartTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let time = calendar.dateComponents([.hour], from: nextHour)
        var day = calendar.dateComponents([.year, .month, .day], from: viewModel.form.date)
        day.hour = time.hour
        day.minute = 0
        day.second = 0
        return calendar.date(from: day) ?? viewModel.form.date
    }

    func defaultEndTime() -> Date {
        let start = defaultStartTime()
        return Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
    }
}
