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
        }
        .onAppear {
            AnalyticsHelper.logScreen(
                screenName: "schedule_edit",
                label: viewModel.mode.analyticsModeLabel == "추가" ? "일정 추가 화면" : "일정 수정 화면",
                parameters: scheduleAnalyticsParameters()
            )
        }
        .onChange(of: viewModel.form.shouldNotify) { _, isEnabled in
            AnalyticsHelper.logAction(
                actionName: "notification_toggle",
                label: isEnabled ? "일정 알림 켜기" : "일정 알림 끄기",
                parameters: scheduleAnalyticsParameters()
            )
        }
        .onChange(of: viewModel.form.notificationLeadTime) { _, leadTime in
            AnalyticsHelper.logAction(
                actionName: "notification_lead_change",
                label: "일정 알림 시간 변경",
                parameters: scheduleAnalyticsParameters().merging([
                    "notification_lead_time": leadTime.displayText
                ]) { _, new in new }
            )
        }
    }
}

// MARK: - Save
private extension ScheduleEditView {
    func save() {
        let feedback = viewModel.save()
        AnalyticsHelper.logAction(
            actionName: "schedule_save",
            label: feedback == .none ? "일정 저장 성공" : "일정 저장 알림 경고",
            parameters: scheduleAnalyticsParameters().merging([
                "save_result": feedback == .none ? "성공" : "알림 경고"
            ]) { _, new in new }
        )

        if feedback == .none {
            dismiss()
        }
    }
    
    func deleteItem() {
        if viewModel.deleteButtonTapped() {
            AnalyticsHelper.logAction(
                actionName: "schedule_delete",
                label: "일정 삭제 성공",
                parameters: scheduleAnalyticsParameters()
            )
            dismiss()
        } else {
            AnalyticsHelper.logAction(
                actionName: "schedule_delete_blocked",
                label: "일정 삭제 차단",
                parameters: scheduleAnalyticsParameters()
            )
        }
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

    func scheduleAnalyticsParameters() -> [String: Any] {
        [
            "schedule_kind": viewModel.kind.analyticsLabel,
            "edit_mode": viewModel.mode.analyticsModeLabel,
            "time_type": timeTypeLabel,
            "notification_enabled": viewModel.form.shouldNotify ? 1 : 0,
            "notification_lead_time": viewModel.form.shouldNotify
                ? viewModel.form.notificationLeadTime.displayText
                : "사용 안 함",
            "has_place": viewModel.form.place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
        ]
    }

    var timeTypeLabel: String {
        switch viewModel.kind {
        case .qwer:
            switch viewModel.form.qwerTimeStatus {
            case .allDay:
                return "하루종일"
            case .timed:
                return "시간 있음"
            case .unspecified:
                return "시간 미정"
            }
        case .user:
            return viewModel.form.isAllDay ? "하루종일" : "시간 있음"
        }
    }
}
