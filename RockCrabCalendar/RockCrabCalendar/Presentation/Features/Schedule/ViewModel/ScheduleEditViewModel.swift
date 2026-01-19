//
//  ScheduleEditViewModel.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/01/15.
//

import Foundation
import SwiftUI
import RockCrabDomain

@Observable
final class ScheduleEditViewModel {
    let mode: ScheduleEditMode
    let qwerVM: QWERScheduleViewModel
    let userVM: UserScheduleViewModel
    private let actionHandler: ScheduleEditActionHandler

    var form: ScheduleEditFormState
    var showNonDeletableAlert: Bool = false
    var isQWERLocalSchedule: Bool = false

    var kind: ScheduleEditKind { mode.kind }

    var titleText: String {
        switch mode {
        case .create(let kind):
            return kind == .qwer ? "QWER 일정 추가" : "개인 일정 추가"
        case .editQWER:
            return "QWER 일정 편집"
        case .editUser:
            return "개인 일정 편집"
        }
    }

    var isSaveDisabled: Bool {
        form.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        mode: ScheduleEditMode,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple,
        notificationManager: NotificationScheduling = NotificationManager.shared
    ) {
        self.mode = mode
        self.qwerVM = qwerVM
        self.userVM = userVM
        self.actionHandler = ScheduleEditActionHandler(
            qwerVM: qwerVM,
            userVM: userVM,
            notificationManager: notificationManager
        )
        self.form = ScheduleEditFormState(
            mode: mode,
            defaultDate: defaultDate,
            defaultColor: defaultColor
        )
    }

    convenience init(
        kind: ScheduleEditKind,
        defaultDate: Date = Date(),
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        defaultColor: Color = .purple,
        notificationManager: NotificationScheduling = NotificationManager.shared
    ) {
        self.init(
            mode: .create(kind),
            defaultDate: defaultDate,
            qwerVM: qwerVM,
            userVM: userVM,
            defaultColor: defaultColor,
            notificationManager: notificationManager
        )
    }

    func refreshLocalFlagIfNeeded() async {
        guard case .editQWER(let item) = mode else {
            isQWERLocalSchedule = false
            return
        }
        isQWERLocalSchedule = await qwerVM.isLocalSchedule(item)
    }

    func save() {
        actionHandler.save(mode: mode, form: form)
    }

    func deleteButtonTapped() -> Bool {
        switch mode {
        case .editQWER:
            if isQWERLocalSchedule {
                actionHandler.delete(mode: mode)
                return true
            } else {
                showNonDeletableAlert = true
                return false
            }
        case .editUser:
            actionHandler.delete(mode: mode)
            return true
        case .create:
            return false
        }
    }
}
