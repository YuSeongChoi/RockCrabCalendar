//
//  ScheduleRecordTarget.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/21/26.
//

import Foundation
import RockCrabDomain

struct ScheduleRecordTarget: Identifiable, Hashable {
    let kind: ScheduleRecord.LinkedScheduleKind
    let scheduleID: UUID
    let title: String
    let date: Date

    var id: String {
        "\(kind.rawValue)-\(scheduleID.uuidString)"
    }

    init(qwerSchedule: QWERScheduleItem) {
        self.kind = .qwer
        self.scheduleID = qwerSchedule.id
        self.title = qwerSchedule.title
        self.date = qwerSchedule.date
    }

    init(userSchedule: UserScheduleItem) {
        self.kind = .user
        self.scheduleID = userSchedule.id
        self.title = userSchedule.title
        self.date = userSchedule.date
    }

    init(record: ScheduleRecord) {
        self.kind = record.linkedSchedule.kind
        self.scheduleID = record.linkedSchedule.scheduleID
        self.title = record.linkedSchedule.title
        self.date = record.linkedSchedule.date
    }

    var snapshot: ScheduleRecord.LinkedScheduleSnapshot {
        ScheduleRecord.LinkedScheduleSnapshot(
            kind: kind,
            scheduleID: scheduleID,
            title: title,
            date: date
        )
    }
}
