//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI
import UIKit

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ScheduleEditViewModel

    init(viewModel: ScheduleEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            Form {
                ScheduleEditBasicInfoSection(
                    title: $viewModel.form.title,
                    date: $viewModel.form.date,
                    isAllDay: $viewModel.form.isAllDay,
                    startTime: $viewModel.form.startTime,
                    endTime: $viewModel.form.endTime,
                    qwerTimeStatus: viewModel.kind == .qwer ? $viewModel.form.qwerTimeStatus : nil,
                    shouldNotify: $viewModel.form.shouldNotify,
                    notificationLeadTime: $viewModel.form.notificationLeadTime,
                    place: $viewModel.form.place,
                    notificationAuthorizationStatus: viewModel.notificationAuthorizationStatus,
                    notificationAvailability: viewModel.notificationAvailability,
                    openNotificationSettings: openNotificationSettings,
                    defaultStartTime: defaultStartTime,
                    defaultEndTime: defaultEndTime,
                    rowBackground: listRowBackgroundColor
                )
                
                if viewModel.kind == .qwer {
                    ScheduleEditQWERSection(
                        mode: viewModel.mode,
                        isLocalOnly: viewModel.isQWERLocalSchedule,
                        category: $viewModel.form.category,
                        selectedMembers: $viewModel.form.selectedMembers,
                        memberColor: QWERStyleMapper.memberColor,
                        rowBackground: listRowBackgroundColor
                    )
                } else {
                    ScheduleEditUserSection(
                        isRepeat: $viewModel.form.isRepeat,
                        repeatType: $viewModel.form.repeatType,
                        repeatEndDate: $viewModel.form.repeatEndDate,
                        selectedColor: $viewModel.form.selectedColor,
                        rowBackground: listRowBackgroundColor
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
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
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("삭제할 수 없습니다", isPresented: $viewModel.showNonDeletableAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("Firestore에 올라간 QWER 일정은 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제할 수 있어요.")
        }
        .alert("알림 안내", isPresented: $viewModel.showSaveFeedbackAlert) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text(viewModel.saveFeedbackMessage)
        }
        .task {
            await viewModel.refreshLocalFlagIfNeeded()
            await viewModel.refreshNotificationAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await viewModel.refreshNotificationAuthorizationStatus()
            }
        }
        .onAppear {
            AnalyticsHelper.logEvent(eventName: "schedule_edit_screen", parameters: ["label":"일정수정화면"])
        }
    }
}

// MARK: - Save
private extension ScheduleEditView {
    func save() {
        let feedback = viewModel.save()

        if feedback == .none {
            dismiss()
        }
    }
    
    func deleteItem() {
        if viewModel.deleteButtonTapped() {
            dismiss()
        }
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Sections
private extension ScheduleEditView {
    var listRowBackgroundColor: Color {
        return Color.cardBackground
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
