//
//  ScheduleEditActionHandler.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/01/15.
//

import Foundation
import RockCrabDomain

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

    func save(mode: ScheduleEditMode, form: ScheduleEditFormState) {
        switch mode {
        case .create(let kind):
            switch kind {
            case .qwer:
                let item = form.buildQWERSchedule()
                qwerVM.addLocal(item)
                if item.shouldNotify {
                    notificationManager.schedule(for: item)
                }
            case .user:
                let item = form.buildUserSchedule()
                userVM.add(item)
                if item.shouldNotify {
                    notificationManager.schedule(for: item)
                }
            }
        case .editQWER(let original):
            let updated = form.buildQWERSchedule(id: original.id)
            qwerVM.updateLocal(updated)
            updateNotifications(for: updated)
        case .editUser(let original):
            let updated = form.buildUserSchedule(id: original.id)
            userVM.update(updated)
            updateNotifications(for: updated)
        }
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

    private func updateNotifications<T: SchedulableItemProtocol>(for schedule: T) {
        if schedule.shouldNotify {
            notificationManager.schedule(for: schedule)
        } else {
            notificationManager.cancel(for: schedule)
        }
    }
}
