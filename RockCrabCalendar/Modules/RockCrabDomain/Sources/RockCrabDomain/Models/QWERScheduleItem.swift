//
//  QWERScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation
import RockCrabShared

public struct QWERScheduleItem: SchedulableItemProtocol, Identifiable, Codable {
    public enum TimeStatus: String, Codable, Equatable {
        case allDay
        case timed
        case unspecified
    }

    public var id: UUID
    /// 스케줄명
    public var title: String
    /// 날짜
    public var date: Date
    /// 시간 (legacy, deprecated)
    private var legacyTime: String
    @available(*, deprecated, message: "Use isAllDay/startTime/endTime instead")
    public var time: String {
        get { legacyTime }
        set { legacyTime = newValue }
    }
    /// 하루종일 여부
    public var isAllDay: Bool
    /// 시작시간
    public var startTime: Date?
    /// 종료시간
    public var endTime: Date?
    /// 시간 상태(종일/시간있음/미정)
    public var timeStatus: TimeStatus
    /// 장소
    public var place: String
    /// 알람여부
    public var shouldNotify: Bool
    /// 일정별 알림 시각
    public var notificationLeadTime: NotificationLeadTime?
    /// 참석멤버
    public var members: [QWERMember]
    public var category: ScheduleCategory

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        time: String = "",
        isAllDay: Bool = true,
        startTime: Date? = nil,
        endTime: Date? = nil,
        timeStatus: TimeStatus? = nil,
        place: String,
        shouldNotify: Bool = false,
        notificationLeadTime: NotificationLeadTime? = nil,
        members: [QWERMember],
        category: ScheduleCategory
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.legacyTime = time
        self.isAllDay = isAllDay
        self.startTime = startTime
        self.endTime = endTime
        self.timeStatus = timeStatus ?? .allDay
        self.place = place
        self.shouldNotify = shouldNotify
        self.notificationLeadTime = notificationLeadTime
        self.members = QWERMember.fixedSorted(members)
        self.category = category

        migrateLegacyTimeIfNeeded()
        normalizeTimeState()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case time          // legacy keep
        case isAllDay
        case startTime
        case endTime
        case timeStatus
        case place
        case shouldNotify
        case notificationLeadTime
        case members
        case category
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode id if present (local UserDefaults), otherwise generate (Firestore docs won't have id field)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)

        self.date = try container.decode(Date.self, forKey: .date)
        self.legacyTime = (try? container.decode(String.self, forKey: .time)) ?? ""

        self.startTime = try? container.decode(Date.self, forKey: .startTime)
        self.endTime = try? container.decode(Date.self, forKey: .endTime)
        self.timeStatus = (try? container.decode(TimeStatus.self, forKey: .timeStatus)) ?? .allDay
        if let decodedIsAllDay = try? container.decode(Bool.self, forKey: .isAllDay) {
            self.isAllDay = decodedIsAllDay
        } else {
            self.isAllDay = (self.startTime == nil && self.endTime == nil)
        }

        self.place = (try? container.decode(String.self, forKey: .place)) ?? ""
        self.shouldNotify = (try? container.decode(Bool.self, forKey: .shouldNotify)) ?? false
        self.notificationLeadTime = try? container.decode(NotificationLeadTime.self, forKey: .notificationLeadTime)

        let rawMembers = (try? container.decode([String].self, forKey: .members)) ?? []
        self.members = QWERMember.fixedSorted(rawMembers.compactMap { QWERMember(rawValue: $0) })
        self.category = ScheduleCategory(rawValue: (try? container.decode(String.self, forKey: .category)) ?? "") ?? .other

        migrateLegacyTimeIfNeeded()
        normalizeTimeState()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(legacyTime, forKey: .time)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(timeStatus, forKey: .timeStatus)
        try container.encode(place, forKey: .place)
        try container.encode(shouldNotify, forKey: .shouldNotify)
        try container.encodeIfPresent(notificationLeadTime, forKey: .notificationLeadTime)
        try container.encode(members.map { $0.rawValue }, forKey: .members)
        try container.encode(category.rawValue, forKey: .category)
    }
}

public enum ScheduleCategory: String, Codable, Equatable, CaseIterable {
    case fanSign = "팬사인회"
    case concert = "공연"
    case award = "시상식"
    case birthday = "생일"
    case other = "기타"

    public var displayName: String {
        AppLocalization.string(rawValue, value: rawValue)
    }
}

extension QWERScheduleItem {
    public var displayTime: String {
        if timeStatus == .allDay { return AppLocalization.string("하루종일", value: "하루종일") }
        if timeStatus == .unspecified { return AppLocalization.string("시간 미정", value: "시간 미정") }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = AppLocalization.locale
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        if let s = startTime, let e = endTime {
            return withTimeZoneSuffix("\(f.string(from: s)) ~ \(f.string(from: e))")
        } else if let s = startTime {
            return withTimeZoneSuffix(f.string(from: s))
        }
        return legacyTime.isEmpty ? AppLocalization.string("시간 미정", value: "시간 미정") : withTimeZoneSuffix(legacyTime)
    }
    public var displayPlace: String {
        place.isEmpty ? AppLocalization.string("장소 미정", value: "장소 미정") : place
    }

    private func withTimeZoneSuffix(_ value: String) -> String {
        guard AppLocalization.prefersEnglish else { return value }
        return "\(value) KST"
    }
}

private extension QWERScheduleItem {
    mutating func migrateLegacyTimeIfNeeded() {
        guard !legacyTime.isEmpty, startTime == nil else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = .autoupdatingCurrent
        if let parsed = formatter.date(from: legacyTime) {
            startTime = parsed
        }
    }

    mutating func normalizeTimeState() {
        if isAllDay && (startTime != nil || endTime != nil) {
            isAllDay = false
        }

        if isAllDay {
            timeStatus = .allDay
            startTime = nil
            endTime = nil
            return
        }

        if startTime != nil || endTime != nil || !legacyTime.isEmpty {
            timeStatus = .timed
            return
        }

        timeStatus = .unspecified
    }
}

// MARK: - QWER 스케줄 모음
extension QWERScheduleItem {
    public static var simpleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }

    public static var simpleTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }
    
    public static let schedules: [QWERScheduleItem] = [
        QWERScheduleItem(
            title: "히나 생일",
            date: simpleDateFormatter.date(from: "2025-01-30")!,
            time: "",
            place: "",
            members: [.E],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "시연 생일",
            date: simpleDateFormatter.date(from: "2025-05-16")!,
            time: "",
            place: "",
            members: [.R],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "위버스콘",
            date: simpleDateFormatter.date(from: "2025-06-01")!,
            time: "14:50",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:50"),
            place: "인스파이어 아레나",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "마젠타 생일",
            date: simpleDateFormatter.date(from: "2025-06-02")!,
            time: "",
            place: "",
            members: [.W],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "난네온불 쇼케이스",
            date: simpleDateFormatter.date(from: "2025-06-09")!,
            time: "19:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "19:00"),
            place: "예스24 원더로크홀",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "부산 원아시아 페스티벌",
            date: simpleDateFormatter.date(from: "2025-06-12")!,
            time: "18:30",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:30"),
            place: "BEXCO 제 1전시장",
            members: [.W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "뷰티풀 민트 라이프",
            date: simpleDateFormatter.date(from: "2025-06-13")!,
            time: "18:20",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:20"),
            place: "올림픽공원",
            members: [.W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "푸본 G!POP",
            date: simpleDateFormatter.date(from: "2025-06-14")!,
            time: "",
            place: "타이베이돔",
            members: [.W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "M COUNTDOWN 사전녹화",
            date: simpleDateFormatter.date(from: "2025-06-19")!,
            time: "13:20",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:20"),
            place: "CJ ENM",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "서울가요대상",
            date: simpleDateFormatter.date(from: "2025-06-21")!,
            time: "18:30",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:30"),
            place: "인스파이어 아레나",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        QWERScheduleItem(
            title: "아노블리어 팝업",
            date: simpleDateFormatter.date(from: "2025-06-27")!,
            time: "19:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "19:00"),
            place: "서울 성동구 상원1길 5 1층",
            members: [.W],
            category: .other
        ),
        QWERScheduleItem(
            title: "위버스 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-28")!,
            time: "20:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "20:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-29")!,
            time: "18:30",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:30"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "더현대닷컴 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-05")!,
            time: "15:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "15:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-06")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-12")!,
            time: "14:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-13")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "캐리비안베이 워터뮤직풀파티",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "14:30",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:30"),
            place: "캐리비안 베이",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "18:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "마이스타굿즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-20")!,
            time: "14:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-26")!,
            time: "14:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-27")!,
            time: "17:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "17:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "펜타포트 락 페스티벌 2025",
            date: simpleDateFormatter.date(from: "2025-08-01")!,
            time: "13:50",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:50"),
            place: "송도달빛축제공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-02")!,
            time: "14:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-03")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "울산 서머 페스티벌",
            date: simpleDateFormatter.date(from: "2025-08-05")!,
            time: "19:30",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "19:30"),
            place: "울산보조경기장 종합운동장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "M COUNTDOWN in Boryeong",
            date: simpleDateFormatter.date(from: "2025-08-07")!,
            time: "18:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "18:00"),
            place: "대천해수욕장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "케이팝스토어 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-09")!,
            time: "14:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "14:00"),
            place: "",
            members: [.W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-10")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "KBO 삼성라이온즈 시구",
            date: simpleDateFormatter.date(from: "2025-08-12")!,
            time: "",
            place: "대구 삼성라이온즈파크",
            members: [.W],
            category: .other
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-16")!,
            time: "15:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "15:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "7rock prime 2025",
            date: simpleDateFormatter.date(from: "2025-08-16")!,
            time: "19:40",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "19:40"),
            place: "잠실실내체육관",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-17")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "K WORLD DREAM AWARDS",
            date: simpleDateFormatter.date(from: "2025-08-21")!,
            time: "",
            place: "잠실실내체육관",
            members: [.W, .E, .R],
            category: .award
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회 (특별공연)",
            date: simpleDateFormatter.date(from: "2025-08-23")!,
            time: "19:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "19:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "부산 INTERNATIONAL ROCK FESTIVAL",
            date: simpleDateFormatter.date(from: "2025-09-26")!,
            time: "15:10",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "15:10"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "PMPS SEASON2 FINALS 축하공연",
            date: simpleDateFormatter.date(from: "2025-09-27")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "ASIA TOP ARTIST FESTIVAL",
            date: simpleDateFormatter.date(from: "2025-09-28")!,
            time: "",
            place: "난지 한강공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ROCKATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-03")!,
            time: "17:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "17:00"),
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ROCKATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-04")!,
            time: "17:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "17:00"),
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ROCKATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-05")!,
            time: "17:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "17:00"),
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "Beyond the Discord LP 판매",
            date: simpleDateFormatter.date(from: "2025-10-13")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "웰컴레코즈",
            members: [.Q, .W, .E, .R],
            category: .other
        ),
        QWERScheduleItem(
            title: "2주년 팝업 BORN2ROCK",
            date: simpleDateFormatter.date(from: "2025-10-17")!,
            time: "네이버 예약",
            place: "무신사 스토어 성수 @대림창고",
            members: [.Q, .W, .E, .R],
            category: .other
        ),
        QWERScheduleItem(
            title: "데뷔 2주년",
            date: simpleDateFormatter.date(from: "2025-10-18")!,
            time: "",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .other
        ),
        QWERScheduleItem(
            title: "MADLY MADLEY",
            date: simpleDateFormatter.date(from: "2025-10-19")!,
            time: "",
            place: "파라다이스 시티",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "Beyond the Discord LP 판매(JP)",
            date: simpleDateFormatter.date(from: "2025-10-22")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "후쿠오카, 오사카, 도쿄",
            members: [.Q, .W, .E, .R],
            category: .other
        ),
        QWERScheduleItem(
            title: "WORLD TOUR BROOKLYN",
            date: simpleDateFormatter.date(from: "2025-11-01")!,
            time: "09:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "09:00"),
            place: "Music Hall of Williamsburg",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "쵸단 생일",
            date: simpleDateFormatter.date(from: "2025-11-01")!,
            time: "",
            place: "",
            members: [.Q],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ATLANTA",
            date: simpleDateFormatter.date(from: "2025-11-03")!,
            time: "10:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "10:00"),
            place: "Terminal West",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR BERWYN",
            date: simpleDateFormatter.date(from: "2025-11-06")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "Distro Music Hall",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR MINNEAPOLIS",
            date: simpleDateFormatter.date(from: "2025-11-08")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "The Lyric at Skyway Theatre",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR FORT WORTH",
            date: simpleDateFormatter.date(from: "2025-11-12")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "Ridglea Theater",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR HOUSTON",
            date: simpleDateFormatter.date(from: "2025-11-13")!,
            time: "11:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "11:00"),
            place: "Warehouse Live",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR SAN FRANCISCO",
            date: simpleDateFormatter.date(from: "2025-11-15")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "Cowell Theater",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR LOS ANGELES",
            date: simpleDateFormatter.date(from: "2025-11-17")!,
            time: "13:00",
            isAllDay: false,
            startTime: simpleTimeFormatter.date(from: "13:00"),
            place: "Vermont Hollywood",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "ASIA ARTIST AWARDS 2025",
            date: simpleDateFormatter.date(from: "2025-12-06")!,
            time: "",
            place: "대만 가오슝 내셔널 스타디움",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        QWERScheduleItem(
            title: "ACON 2025 FESTA",
            date: simpleDateFormatter.date(from: "2025-12-07")!,
            startTime: simpleTimeFormatter.date(from: "18:00"),
            place: "대만 가오슝 내셔널 스타디움",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "우리은행 QWER Special Stage",
            date: simpleDateFormatter.date(from: "2025-12-13")!,
            time: "",
            place: "롯데시네마 월드타워점",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "서울 코스프레 페스티벌",
            date: simpleDateFormatter.date(from: "2025-12-21")!,
            time: "",
            place: "고양시 KINTEX",
            members: [.W, .E],
            category: .other
        ),
        QWERScheduleItem(
            title: "크리스마스 파티 위버스 라이브",
            date: simpleDateFormatter.date(from: "2025-12-24")!,
            startTime: simpleTimeFormatter.date(from: "19:00"),
            place: "위버스 라이브",
            members: [.Q, .W, .E, .R],
            category: .other
        ),
        QWERScheduleItem(
            title: "위버스 팬사인회",
            date: simpleDateFormatter.date(from: "2025-12-27")!,
            time: "",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "WORLD K-POP Festival Countdown",
            date: simpleDateFormatter.date(from: "2026-01-01")!,
            startTime: simpleTimeFormatter.date(from: "02:25"),
            place: "DDP 아트홀 1관",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR MACAU",
            date: simpleDateFormatter.date(from: "2026-01-03")!,
            time: "",
            place: "The Londoner Theatre",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR KUALA LUMPUR",
            date: simpleDateFormatter.date(from: "2026-01-17")!,
            time: "",
            place: "Zepp Kuala Lumpur",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "배성재의 TEN 생녹방",
            date: simpleDateFormatter.date(from: "2026-01-23")!,
            time: "19:00",
            place: "SBS 파워FM",
            members: [.Q, .E],
            category: .other
        ),
        QWERScheduleItem(
            title: "배성재의 TEN 본방송",
            date: simpleDateFormatter.date(from: "2026-01-25")!,
            time: "22:00",
            place: "SBS 파워FM",
            members: [.Q, .E],
            category: .other
        ),
        QWERScheduleItem(
            title: "히나 생일",
            date: simpleDateFormatter.date(from: "2026-01-30")!,
            time: "",
            place: "",
            members: [.E],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "WORLD TOUR HONG KONG",
            date: simpleDateFormatter.date(from: "2026-02-08")!,
            time: "",
            place: "AsiaWorld-Expo, Runway 11",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING) 팬클럽 선예매 사전 인증 시작",
            date: simpleDateFormatter.date(from: "2026-02-09")!,
            time: "14:00",
            place: "멜론티켓",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "2026 D AWARDS",
            date: simpleDateFormatter.date(from: "2026-02-11")!,
            time: "18:00",
            place: "고려대학교 화정체육관",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING) 선예매",
            date: simpleDateFormatter.date(from: "2026-02-11")!,
            time: "20:00",
            place: "멜론티켓",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING) 일반예매 시작",
            date: simpleDateFormatter.date(from: "2026-02-13")!,
            time: "20:00",
            place: "멜론티켓",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR TAIPEI",
            date: simpleDateFormatter.date(from: "2026-02-14")!,
            time: "",
            place: "TICC",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR TAIPEI",
            date: simpleDateFormatter.date(from: "2026-02-15")!,
            time: "",
            place: "TICC",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR FUKUOKA",
            date: simpleDateFormatter.date(from: "2026-02-19")!,
            time: "",
            place: "Zepp Fukuoka",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR OSAKA",
            date: simpleDateFormatter.date(from: "2026-02-20")!,
            time: "",
            place: "Zepp Osaka Bayside",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR TOKYO",
            date: simpleDateFormatter.date(from: "2026-02-22")!,
            time: "",
            place: "Zepp DiverCity",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR SINGAPORE",
            date: simpleDateFormatter.date(from: "2026-02-28")!,
            time: "",
            place: "The Theatre at Mediacorp",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING)",
            date: simpleDateFormatter.date(from: "2026-03-20")!,
            time: "19:00",
            place: "티켓링크 라이브 아레나(올림픽공원 핸드볼경기장)",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING)",
            date: simpleDateFormatter.date(from: "2026-03-21")!,
            time: "17:00",
            place: "티켓링크 라이브 아레나(올림픽공원 핸드볼경기장)",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "QWER WORLD TOUR(ROCKATION - HOMECOMING)",
            date: simpleDateFormatter.date(from: "2026-03-22")!,
            time: "16:00",
            place: "티켓링크 라이브 아레나(올림픽공원 핸드볼경기장)",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "인천 개항장 페스타 1901 LIVE ROAD",
            date: simpleDateFormatter.date(from: "2026-03-29")!,
            time: "21:00",
            place: "인천 개항장 문화지구일원 (상상플랫폼 등)",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "아주대학교 A-LOG",
            date: simpleDateFormatter.date(from: "2026-04-03")!,
            time: "17:30",
            place: "아주대학교 노천극장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "체리 블라썸 뮤직 페스티벌",
            date: simpleDateFormatter.date(from: "2026-04-05")!,
            time: "14:00",
            place: "진해공설운동장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "JJ50th Anniversary Fest 2026",
            date: simpleDateFormatter.date(from: "2026-04-18")!,
            time: "15:00",
            place: "피아 아레나 MM",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "THIS IS OUR CEREMONY",
            date: simpleDateFormatter.date(from: "2026-04-19")!,
            time: "15:00",
            place: "북서울꿈의숲 창포원 야외무대",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "2026 서울 히어로 락 페스티벌 x 트리헌드레드",
            date: simpleDateFormatter.date(from: "2026-04-25")!,
            time: "",
            place: "문화비축기지",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "CEREMONY MV RELEASE & SHOWCASE",
            date: simpleDateFormatter.date(from: "2026-04-27")!,
            time: "19:00",
            place: "신촌 원더로크",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "포스코 노동조합 K-노사문화 콘서트",
            date: simpleDateFormatter.date(from: "2026-05-14")!,
            time: "",
            place: "포항 종합운동장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "시연 생일",
            date: simpleDateFormatter.date(from: "2026-05-16")!,
            time: "",
            place: "",
            members: [.R],
            category: .birthday
        ),
        QWERScheduleItem(
            title: "위버스 팬사인회",
            date: simpleDateFormatter.date(from: "2026-05-16")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "YOUTH WAVE: THE BAND NIGHT",
            date: simpleDateFormatter.date(from: "2026-05-16")!,
            time: "18:00",
            place: "광운대학교 동해문화예술관대극장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "PEAK FESTIVAL 2026",
            date: simpleDateFormatter.date(from: "2026-05-23")!,
            time: "",
            place: "난지 한강공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "슈퍼레이스 x 서울파크뮤직페스티벌",
            date: simpleDateFormatter.date(from: "2026-05-24")!,
            time: "19:20",
            place: "영암 국제 자동차 경주장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "2026 푸본 G!POP 뮤직페스티벌",
            date: simpleDateFormatter.date(from: "2026-05-30")!,
            time: "",
            place: "타이베이돔",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WEVERSE CON FESTIVAL",
            date: simpleDateFormatter.date(from: "2026-06-06")!,
            time: "",
            place: "올림픽공원 KSPO DOME, 88잔디마당",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "The 21th KKBOX Music Awards(대만)",
            date: simpleDateFormatter.date(from: "2026-06-13")!,
            time: "18:00",
            place: "대만 타이베이 아레나",
            members: [.Q, .W, .E, .R],
            category: .concert
        )
    ]
}
