//
//  UserScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

public struct UserScheduleItem: SchedulableItemProtocol, Identifiable, Codable {
    public let id: UUID
    /// 스케줄명
    public var title: String
    /// 날짜
    public var date: Date
    /// 시간
    @available(*, deprecated, message: "Use isAllDay/startTime/endTime instead")
    public var time: String
    /// 하루종일 여부
    public var isAllDay: Bool
    /// 시작시간
    public var startTime: Date?
    /// 종료시간
    public var endTime: Date?
    /// 장소
    public var place: String
    /// 알람여부
    public var shouldNotify: Bool
    /// 반복 여부
    public var isRepeat: Bool
    /// 반복 종류
    public var repeatType: RepeatType?
    /// 반복 끝나는 날짜
    public var repeatEndDate: Date?
    /// 일정 색상 HEX
    public var colorHex: String
    
    public init(
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
            formatter.locale = .autoupdatingCurrent
            if let parsed = formatter.date(from: time) {
                self.startTime = parsed
                self.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: parsed)
                self.isAllDay = false
            }
        }
    }
    
    public var displayTime: String {
        if isAllDay { return NSLocalizedString("하루종일", bundle: .main, value: "하루종일", comment: "") }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        if let s = startTime, let e = endTime {
            return "\(f.string(from: s)) ~ \(f.string(from: e))"
        }
        return time.isEmpty ? NSLocalizedString("시간 미정", bundle: .main, value: "시간 미정", comment: "") : time
    }
    public var displayPlace: String {
        place.isEmpty ? NSLocalizedString("장소 미정", bundle: .main, value: "장소 미정", comment: "") : place
    }
}

extension UserScheduleItem {
    public enum RepeatType: String ,Codable, CaseIterable {
        case none = "없음"
        case day = "매일"
        case week = "매주"
        case month = "매월"
        case year = "매년"

        public var displayName: String {
            NSLocalizedString(rawValue, bundle: .main, value: rawValue, comment: "")
        }
    }
}
