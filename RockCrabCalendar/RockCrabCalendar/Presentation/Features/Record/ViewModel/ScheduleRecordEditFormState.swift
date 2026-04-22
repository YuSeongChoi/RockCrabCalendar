//
//  ScheduleRecordEditFormState.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 4/21/26.
//

import Foundation
import RockCrabDomain

struct ScheduleRecordEditFormState {
    var emoji: String
    var title: String
    var body: String

    init(record: ScheduleRecord? = nil, target: ScheduleRecordTarget) {
        self.emoji = record?.emoji ?? "🦀"
        self.title = record?.title ?? target.title
        self.body = record?.body ?? ""
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedEmoji: String {
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "🦀" }
        return String(trimmed.prefix(1))
    }

    var canSave: Bool {
        trimmedTitle.isEmpty == false || trimmedBody.isEmpty == false
    }
}
