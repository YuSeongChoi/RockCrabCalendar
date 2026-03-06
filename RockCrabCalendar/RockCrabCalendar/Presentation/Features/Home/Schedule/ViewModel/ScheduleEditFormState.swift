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
    var qwerTimeStatus: QWERScheduleItem.TimeStatus
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
            self.qwerTimeStatus = .allDay
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
            self.time = Self.legacyTimeString(
                isAllDay: item.isAllDay,
                startTime: item.startTime
            )
            self.place = item.place
            self.isAllDay = item.isAllDay
            self.startTime = item.startTime
            self.endTime = item.endTime
            self.qwerTimeStatus = item.timeStatus
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
            self.time = Self.legacyTimeString(
                isAllDay: item.isAllDay,
                startTime: item.startTime
            )
            self.place = item.place
            self.isAllDay = item.isAllDay
            self.startTime = item.startTime
            self.endTime = item.endTime
            self.qwerTimeStatus = .allDay
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
        let normalizedStartTime = qwerTimeStatus == .timed ? startTime : nil
        let normalizedEndTime = qwerTimeStatus == .timed ? endTime : nil
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = .autoupdatingCurrent
        let trimmedTime = trimmed(time)
        let legacyTime = qwerTimeStatus == .timed
            ? (trimmedTime.isEmpty ? (normalizedStartTime.map { formatter.string(from: $0) } ?? "") : trimmedTime)
            : ""

        return QWERScheduleItem(
            id: id ?? UUID(),
            title: trimmed(title),
            date: date,
            time: legacyTime,
            isAllDay: qwerTimeStatus == .allDay,
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            timeStatus: qwerTimeStatus,
            place: trimmed(place),
            shouldNotify: qwerTimeStatus == .timed ? shouldNotify : false,
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

    private static func legacyTimeString(isAllDay: Bool, startTime: Date?) -> String {
        guard !isAllDay, let startTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = .autoupdatingCurrent
        return formatter.string(from: startTime)
    }
}
