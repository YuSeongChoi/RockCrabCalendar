//
//  UserScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

struct UserScheduleItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var time: String
    var place: String
    var note: String?
    var alertMinutesBefore: Int?
    var isRepeat: Bool
    var repeatType: RepeatType?
    var repeatEndDate: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String,
        place: String,
        note: String? = nil,
        alertMinutesBefore: Int? = nil,
        isRepeat: Bool = false,
        repeatType: RepeatType? = nil,
        repeatEndDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.place = place
        self.note = note
        self.alertMinutesBefore = alertMinutesBefore
        self.isRepeat = isRepeat
        self.repeatType = repeatType
        self.repeatEndDate = repeatEndDate
    }
}

extension UserScheduleItem {
    enum RepeatType: String ,Codable, CaseIterable {
        case none = "없음"
        case week = "매주"
        case month = "매월"
        case year = "매년"
    }
}
