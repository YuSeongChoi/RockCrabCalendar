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

    func save(mode: ScheduleEditMode, form: ScheduleEditFormState) {
        switch mode {
        case .create(let kind):
            switch kind {
            case .qwer:
                let item = form.buildQWERSchedule()
                qwerVM.addLocal(item)
                if item.shouldNotify {
                    NotificationManager.shared.schedule(for: item)
                }
            case .user:
                let item = form.buildUserSchedule()
                userVM.add(item)
                if item.shouldNotify {
                    NotificationManager.shared.schedule(for: item)
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
            NotificationManager.shared.cancel(for: original)
            qwerVM.deleteLocal(original)
        case .editUser(let original):
            NotificationManager.shared.cancel(for: original)
            userVM.delete(original)
        case .create:
            break
        }
    }

    private func updateNotifications<T: SchedulableItemProtocol>(for schedule: T) {
        if schedule.shouldNotify {
            NotificationManager.shared.schedule(for: schedule)
        } else {
            NotificationManager.shared.cancel(for: schedule)
        }
    }
}
