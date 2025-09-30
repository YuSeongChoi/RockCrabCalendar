//
//  UserScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

struct UserScheduleItem: SchedulableItem, Identifiable, Codable {
    let id: UUID
    /// 스케줄명
    var title: String
    /// 날짜
    var date: Date
    /// 시간
    var time: String
    /// 장소
    var place: String
    /// 반복 여부
    var isRepeat: Bool
    /// 반복 종류
    var repeatType: RepeatType?
    /// 반복 끝나는 날짜
    var repeatEndDate: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String,
        place: String,
        isRepeat: Bool = false,
        repeatType: RepeatType? = nil,
        repeatEndDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.place = place
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
