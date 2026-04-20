//
//  ScheduleEditActionHandler.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import Foundation
import RockCrabDomain

enum ScheduleSaveFeedback: Equatable {
    case none
    case notificationWarning(String)
}

struct ScheduleEditActionHandler {
    let qwerVM: QWERScheduleViewModel
    let userVM: UserScheduleViewModel
    let notificationManager: NotificationScheduling

    init(
        qwerVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        notificationManager: NotificationScheduling = NotificationManager.shared
    ) {
        self.qwerVM = qwerVM
        self.userVM = userVM
        self.notificationManager = notificationManager
    }

    func save(
        mode: ScheduleEditMode,
        form: ScheduleEditFormState,
        notificationAvailability: NotificationAvailability
    ) -> ScheduleSaveFeedback {
        switch mode {
        case .create(let kind):
            switch kind {
            case .qwer:
                let item = form.buildQWERSchedule()
                qwerVM.addLocal(item)
                applyNotifications(for: item, availability: notificationAvailability)
            case .user:
                let item = form.buildUserSchedule()
                userVM.add(item)
                applyNotifications(for: item, availability: notificationAvailability)
            }
        case .editQWER(let original):
            let updated = form.buildQWERSchedule(id: original.id)
            qwerVM.updateLocal(updated)
            updateNotifications(for: updated, original: original, availability: notificationAvailability)
        case .editUser(let original):
            let updated = form.buildUserSchedule(id: original.id)
            userVM.update(updated)
            updateNotifications(for: updated, original: original, availability: notificationAvailability)
        }

        if let message = notificationAvailability.saveFeedbackMessage {
            return .notificationWarning(message)
        }

        return .none
    }

    func delete(mode: ScheduleEditMode) {
        switch mode {
        case .editQWER(let original):
            notificationManager.cancel(for: original)
            qwerVM.deleteLocal(original)
        case .editUser(let original):
            notificationManager.cancel(for: original)
            userVM.delete(original)
        case .create:
            break
        }
    }

    private func updateNotifications<T: SchedulableItemProtocol>(
        for schedule: T,
        original: T,
        availability: NotificationAvailability
    ) {
        notificationManager.cancel(for: original)
        applyNotifications(for: schedule, availability: availability)
    }

    private func applyNotifications<T: SchedulableItemProtocol>(
        for schedule: T,
        availability: NotificationAvailability
    ) {
        if schedule.shouldNotify, availability == .available {
            notificationManager.schedule(for: schedule)
        } else {
            notificationManager.cancel(for: schedule)
        }
    }
}
