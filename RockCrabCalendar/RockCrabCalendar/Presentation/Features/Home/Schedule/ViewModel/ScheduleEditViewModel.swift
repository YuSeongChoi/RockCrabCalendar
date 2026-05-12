//
//  ScheduleEditViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import Foundation
import SwiftUI
import RockCrabDomain
import RockCrabShared

@Observable
final class ScheduleEditViewModel {
    let mode: ScheduleEditMode
    let qwerVM: QWERScheduleViewModel
    let userVM: UserScheduleViewModel
    private let actionHandler: ScheduleEditActionHandler
    private let notificationManager: NotificationScheduling

    var form: ScheduleEditFormState
    var showNonDeletableAlert: Bool = false
    var showSaveFeedbackAlert: Bool = false
    var isQWERLocalSchedule: Bool = false
    var saveFeedbackMessage: String = ""
    var saveFeedbackAvailability: NotificationAvailability?
    var notificationAuthorizationStatus: NotificationAuthorizationStatus = .notDetermined

    var kind: ScheduleEditKind { mode.kind }

    var isNewUserSchedule: Bool {
        if case .create(.user) = mode {
            return true
        }
        return false
    }

    var titleText: String {
        switch mode {
        case .create(let kind):
            return kind == .qwer
                ? AppLocalization.string("QWER 일정 추가")
                : AppLocalization.string("개인 일정 추가")
        case .editQWER:
            return AppLocalization.string("QWER 일정 편집")
        case .editUser:
            return AppLocalization.string("개인 일정 편집")
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
        self.notificationManager = notificationManager
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
        defaultColor: Color = Color(red: 254/255, green: 225/255, blue: 232/255),
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

    func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await notificationManager.authorizationStatus()
    }

    var notificationAvailability: NotificationAvailability {
        let item: any SchedulableItemProtocol
        switch kind {
        case .qwer:
            item = form.buildQWERSchedule()
        case .user:
            item = form.buildUserSchedule()
        }

        return notificationManager.availability(
            for: item,
            authorizationStatus: notificationAuthorizationStatus
        )
    }

    var shouldOfferNotificationSettingsNavigation: Bool {
        saveFeedbackAvailability == .denied || saveFeedbackAvailability == .notDetermined
    }

    @MainActor
    func save() async -> ScheduleSaveFeedback {
        await refreshNotificationAuthorizationStatus()

        let availability = notificationAvailability
        let feedback = actionHandler.save(
            mode: mode,
            form: form,
            notificationAvailability: availability
        )

        if case .notificationWarning(let message) = feedback {
            saveFeedbackMessage = message
            saveFeedbackAvailability = availability
            showSaveFeedbackAlert = true
        } else {
            saveFeedbackAvailability = nil
        }

        return feedback
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
