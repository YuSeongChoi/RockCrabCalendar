//
//  ScheduleEditView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import SwiftUI
import RockCrabDomain

struct ScheduleEditView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Inputs
    let mode: ScheduleEditMode
    let qwerVM: QWERScheduleViewModel
    let userVM: UserScheduleViewModel
    private let actionHandler: ScheduleEditActionHandler

    private var kind: ScheduleEditKind { mode.kind }

    @State private var form: ScheduleEditFormState

    // Deletion alert state
    @State private var showNonDeletableAlert: Bool = false
    @State private var isQWERLocalSchedule: Bool = false

    // 일정 생성
    init(
        kind: ScheduleEditKind,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple
    ) {
        self.init(
            mode: .create(kind),
            defaultDate: defaultDate,
            qwerVM: qwerVM,
            userVM: userVM,
            defaultColor: defaultColor
        )
    }
    
    // 일정 편집
    init(
        mode: ScheduleEditMode,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple
    ) {
        self.mode = mode
        self.qwerVM = qwerVM
        self.userVM = userVM
        self.actionHandler = ScheduleEditActionHandler(qwerVM: qwerVM, userVM: userVM)
        _form = State(initialValue: ScheduleEditFormState(
            mode: mode,
            defaultDate: defaultDate,
            defaultColor: defaultColor
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                ScheduleEditBasicInfoSection(
                    title: $form.title,
                    date: $form.date,
                    isAllDay: $form.isAllDay,
                    startTime: $form.startTime,
                    endTime: $form.endTime,
                    shouldNotify: $form.shouldNotify,
                    place: $form.place,
                    defaultStartTime: defaultStartTime,
                    defaultEndTime: defaultEndTime
                )
                if kind == .qwer {
                    ScheduleEditQWERSection(
                        mode: mode,
                        isLocalOnly: isQWERLocalSchedule,
                        category: $form.category,
                        selectedMembers: $form.selectedMembers,
                        memberColor: qwerVM.memberColor
                    )
                } else {
                    ScheduleEditUserSection(
                        isRepeat: $form.isRepeat,
                        repeatType: $form.repeatType,
                        repeatEndDate: $form.repeatEndDate,
                        selectedColor: $form.selectedColor
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .listRowBackground(listRowBackgroundColor)
            .background(listBackgroundColor)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Text("저장")
                            .bold()
                    }
                    .disabled(form.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if case .editQWER = mode {
                        Button(role: .destructive) {
                            if isQWERLocalSchedule {
                                deleteItem()
                            } else {
                                showNonDeletableAlert = true
                            }
                        } label: { Text("삭제") }
                    } else if case .editUser = mode {
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
            .alert("삭제할 수 없습니다", isPresented: $showNonDeletableAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("Firestore에 올라간 QWER 일정은 삭제할 수 없습니다.\n사용자가 직접 추가한 QWER 일정만 삭제할 수 있어요.")
            }
        }
        .environment(\.locale, Locale(identifier: "ko_KR"))
        .task {
            await refreshLocalFlagIfNeeded()
        }
        .onAppear {
            AnalyticsHelper.logEvent(eventName: "schedule_edit_screen", parameters: ["label":"일정수정화면"])
        }
    }
    
    private var titleText: String {
        switch mode {
        case .create(let k):
            return k == .qwer ? "QWER 일정 추가" : "개인 일정 추가"
        case .editQWER:
            return "QWER 일정 편집"
        case .editUser:
            return "개인 일정 편집"
        }
    }
    
    // Query ViewModel to determine if the QWER item is local-only.
    private func refreshLocalFlagIfNeeded() async {
        guard case .editQWER(let item) = mode else {
            isQWERLocalSchedule = false
            return
        }
        isQWERLocalSchedule = await qwerVM.isLocalSchedule(item)
    }
}

// MARK: - Save
private extension ScheduleEditView {
    func save() {
        actionHandler.save(mode: mode, form: form)

        dismiss()
    }
    
    func deleteItem() {
        actionHandler.delete(mode: mode)
        
        dismiss()
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
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: form.date) ?? form.date
    }

    func defaultEndTime() -> Date {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: form.date) ?? form.date
    }
}
