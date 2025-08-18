//
//  ScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation
import FirebaseCore

struct ScheduleItem: Identifiable, Codable {
    let id: UUID
    /// 스케줄명
    let title: String
    /// 날짜
    let date: Date
    /// 시간
    let time: String
    /// 장소
    let place: String
    /// 참석멤버
    let members: [QWERMember]
    let category: ScheduleCategory
    
    init(id: UUID = UUID(), title: String, date: Date, time: String, place: String, members: [QWERMember], category: ScheduleCategory) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.place = place
        self.members = members
        self.category = category
    }
    
    enum CodingKeys: String, CodingKey {
        case title, date, time, place, members, category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.time = try container.decode(String.self, forKey: .time)
        self.place = try container.decode(String.self, forKey: .place)
        
        let rawMembers = try container.decode([String].self, forKey: .members)
        self.members = rawMembers.compactMap { QWERMember(rawValue: $0) }
        self.category = ScheduleCategory(rawValue: try container.decode(String.self, forKey: .category)) ?? .other
        // Generate UUID locally since Firestore doc ID is not being used
        self.id = UUID()
    }
}

enum ScheduleCategory: String, Codable, Equatable, CaseIterable {
    case fanSign = "팬사인회"
    case concert = "공연"
    case award = "시상식"
    case birthday = "생일"
    case other = "기타"
}

extension ScheduleItem {
    var asDictionary: [String: Any] {
        return [
            "title": title,
            "date": Timestamp(date: date),
            "time": time,
            "place": place,
            "members": members.map { $0.rawValue },
            "category": category.rawValue
        ]
    }
}

extension ScheduleItem {
    static var simpleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }
    
    static let schedules: [ScheduleItem] = [
        ScheduleItem(
            title: "위버스콘",
            date: simpleDateFormatter.date(from: "2025-06-01")!,
            time: "14:50",
            place: "인스파이어 아레나",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "마젠타 생일",
            date: simpleDateFormatter.date(from: "2025-06-02")!,
            time: "",
            place: "",
            members: [.W],
            category: .birthday
        ),
        ScheduleItem(
            title: "난네온불 쇼케이스",
            date: simpleDateFormatter.date(from: "2025-06-09")!,
            time: "19:00",
            place: "예스24 원더로크홀",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "부산 원아시아 페스티벌",
            date: simpleDateFormatter.date(from: "2025-06-12")!,
            time: "18:30",
            place: "BEXCO 제 1전시장",
            members: [.W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "뷰티풀 민트 라이프",
            date: simpleDateFormatter.date(from: "2025-06-13")!,
            time: "18:20",
            place: "올림픽공원",
            members: [.W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "푸본 G!POP",
            date: simpleDateFormatter.date(from: "2025-06-14")!,
            time: "",
            place: "타이베이돔",
            members: [.W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "M COUNTDOWN 사전녹화",
            date: simpleDateFormatter.date(from: "2025-06-19")!,
            time: "13:20",
            place: "CJ ENM",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "서울가요대상",
            date: simpleDateFormatter.date(from: "2025-06-21")!,
            time: "18:30",
            place: "인스파이어 아레나",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        ScheduleItem(
            title: "아노블리어 팝업",
            date: simpleDateFormatter.date(from: "2025-06-27")!,
            time: "19:00",
            place: "서울 성동구 상원1길 5 1층",
            members: [.W],
            category: .other
        ),
        ScheduleItem(
            title: "위버스 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-28")!,
            time: "20:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-29")!,
            time: "18:30",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "더현대닷컴 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-05")!,
            time: "15:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-06")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-12")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-13")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "캐리비안베이 워터뮤직풀파티",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "14:30",
            place: "캐리비안 베이",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "18:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "마이스타굿즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-20")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-26")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-27")!,
            time: "17:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "펜타포트 락 페스티벌 2025",
            date: simpleDateFormatter.date(from: "2025-08-01")!,
            time: "13:50",
            place: "송도달빛축제공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-02")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-03")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "울산 서머 페스티벌",
            date: simpleDateFormatter.date(from: "2025-08-05")!,
            time: "19:30",
            place: "울산보조경기장 종합운동장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "M COUNTDOWN in Boryeong",
            date: simpleDateFormatter.date(from: "2025-08-07")!,
            time: "18:00",
            place: "대천해수욕장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "케이팝스토어 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-09")!,
            time: "14:00",
            place: "",
            members: [.W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-10")!,
            time: "13:00",
            place: "",
            members: [.W, .E, .R],
            category: .fanSign
        ),
        ScheduleItem(
            title: "7rock prime 2025",
            date: simpleDateFormatter.date(from: "2025-08-16")!,
            time: "19:40",
            place: "잠실실내체육관",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "K WORLD DREAM AWARDS",
            date: simpleDateFormatter.date(from: "2025-08-21")!,
            time: "",
            place: "잠실실내체육관",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        ScheduleItem(
            title: "THE HYPER DAY 2025 DAEGU",
            date: simpleDateFormatter.date(from: "2025-08-30")!,
            time: "12:30",
            place: "대구스타디움 동편 메인광장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "ASIA TOP ARTIST FESTIVAL",
            date: simpleDateFormatter.date(from: "2025-09-28")!,
            time: "",
            place: "난지 한강공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-03")!,
            time: "",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-04")!,
            time: "",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-05")!,
            time: "",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        ScheduleItem(
            title: "MADLY MADLEY",
            date: simpleDateFormatter.date(from: "2025-10-19")!,
            time: "",
            place: "파라다이스 시티",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
    ]
}
