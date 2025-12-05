//
//  UserScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

struct UserScheduleItem: SchedulableItemProtocol, Identifiable, Codable {
    let id: UUID
    /// 스케줄명
    var title: String
    /// 날짜
    var date: Date
    /// 시간
    @available(*, deprecated, message: "Use isAllDay/startTime/endTime instead")
    var time: String
    /// 하루종일 여부
    var isAllDay: Bool
    /// 시작시간
    var startTime: Date?
    /// 종료시간
    var endTime: Date?
    /// 장소
    var place: String
    /// 알람여부
    var shouldNotify: Bool
    /// 반복 여부
    var isRepeat: Bool
    /// 반복 종류
    var repeatType: RepeatType?
    /// 반복 끝나는 날짜
    var repeatEndDate: Date?
    /// 일정 색상 HEX
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String,
        isAllDay: Bool = true,
        startTime: Date? = nil,
        endTime: Date? = nil,
        place: String,
        shouldNotify: Bool = false,
        isRepeat: Bool = false,
        repeatType: RepeatType? = nil,
        repeatEndDate: Date? = nil,
        colorHex: String = "#A78BFA"
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.isAllDay = isAllDay
        self.startTime = startTime
        self.endTime = endTime
        self.place = place
        self.shouldNotify = shouldNotify
        self.isRepeat = isRepeat
        self.repeatType = repeatType
        self.repeatEndDate = repeatEndDate
        self.colorHex = colorHex
        
        if !time.isEmpty && startTime == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            if let parsed = formatter.date(from: time) {
                self.startTime = parsed
                self.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: parsed)
                self.isAllDay = false
            }
        }
    }
    
    var displayTime: String {
        if isAllDay { return "하루종일" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        if let s = startTime, let e = endTime {
            return "\(f.string(from: s)) ~ \(f.string(from: e))"
        }
        return time.isEmpty ? "시간 미정" : time
    }
    var displayPlace: String { place.isEmpty ? "장소 미정" : place }
}

extension UserScheduleItem {
    enum RepeatType: String ,Codable, CaseIterable {
        case none = "없음"
        case week = "매주"
        case month = "매월"
        case year = "매년"
    }
}
