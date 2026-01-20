//
//  ScheduleEditFormState.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import SwiftUI
import RockCrabDomain

struct ScheduleEditFormState {
    var title: String
    var date: Date
    var time: String
    var place: String
    var isAllDay: Bool
    var startTime: Date?
    var endTime: Date?
    var shouldNotify: Bool

    var selectedMembers: Set<QWERMember>
    var category: ScheduleCategory

    var isRepeat: Bool
    var repeatType: UserScheduleItem.RepeatType
    var repeatEndDate: Date
    var selectedColor: Color

    init(mode: ScheduleEditMode, defaultDate: Date, defaultColor: Color) {
        switch mode {
        case .create:
            self.title = ""
            self.date = defaultDate
            self.time = ""
            self.place = ""
            self.isAllDay = true
            self.startTime = nil
            self.endTime = nil
            self.shouldNotify = false
            self.selectedMembers = []
            self.category = .other
            self.isRepeat = false
            self.repeatType = .none
            self.repeatEndDate = defaultDate
            self.selectedColor = defaultColor
        case .editQWER(let item):
            self.title = item.title
            self.date = item.date
            self.time = item.time
            self.place = item.place
            self.isAllDay = item.isAllDay
            self.startTime = item.startTime
            self.endTime = item.endTime
            self.shouldNotify = item.shouldNotify
            self.selectedMembers = Set(item.members)
            self.category = item.category
            self.isRepeat = false
            self.repeatType = .none
            self.repeatEndDate = defaultDate
            self.selectedColor = defaultColor
        case .editUser(let item):
            self.title = item.title
            self.date = item.date
            self.time = item.time
            self.place = item.place
            self.isAllDay = item.isAllDay
            self.startTime = item.startTime
            self.endTime = item.endTime
            self.shouldNotify = item.shouldNotify
            self.selectedMembers = []
            self.category = .other
            self.isRepeat = item.isRepeat
            self.repeatType = item.repeatType ?? .none
            self.repeatEndDate = item.repeatEndDate ?? defaultDate
            self.selectedColor = Color(hex: item.colorHex)
        }
    }

    func buildQWERSchedule(id: UUID? = nil) -> QWERScheduleItem {
        QWERScheduleItem(
            id: id ?? UUID(),
            title: trimmed(title),
            date: date,
            time: trimmed(time),
            isAllDay: isAllDay,
            startTime: isAllDay ? nil : startTime,
            endTime: isAllDay ? nil : endTime,
            place: trimmed(place),
            shouldNotify: shouldNotify,
            members: Array(selectedMembers).sorted { $0.rawValue < $1.rawValue },
            category: category
        )
    }

    func buildUserSchedule(id: UUID? = nil) -> UserScheduleItem {
        UserScheduleItem(
            id: id ?? UUID(),
            title: trimmed(title),
            date: date,
            time: trimmed(time),
            isAllDay: isAllDay,
            startTime: isAllDay ? nil : startTime,
            endTime: isAllDay ? nil : endTime,
            place: trimmed(place),
            shouldNotify: shouldNotify,
            isRepeat: isRepeat,
            repeatType: isRepeat ? repeatType : nil,
            repeatEndDate: isRepeat ? repeatEndDate : nil,
            colorHex: selectedColor.toHexString()
        )
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
