//
//  ScheduleEditMode.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import Foundation
import RockCrabDomain

enum ScheduleEditKind: Hashable {
    case qwer
    case user
}

enum ScheduleEditMode: Hashable, Identifiable {
    case create(ScheduleEditKind)
    case editQWER(QWERScheduleItem)
    case editUser(UserScheduleItem)

    var id: String {
        switch self {
        case .create(let kind):
            return "create_\(kind == .qwer ? "qwer" : "user")"
        case .editQWER(let item):
            return "qwer_\(item.id.uuidString)"
        case .editUser(let item):
            return "user_\(item.id.uuidString)"
        }
    }

    var kind: ScheduleEditKind {
        switch self {
        case .create(let kind):
            return kind
        case .editQWER:
            return .qwer
        case .editUser:
            return .user
        }
    }

    static func == (lhs: ScheduleEditMode, rhs: ScheduleEditMode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
