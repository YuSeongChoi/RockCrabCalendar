//
//  QWERScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

struct QWERScheduleItem: SchedulableItem, Identifiable, Codable {
    var id: UUID
    /// 스케줄명
    var title: String
    /// 날짜
    var date: Date
    /// 시간
    var time: String
    /// 장소
    var place: String
    /// 참석멤버
    var members: [QWERMember]
    var category: ScheduleCategory
    
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
        case id
        case title
        case date
        case time
        case place
        case members
        case category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode id if present (local UserDefaults), otherwise generate (Firestore docs won't have id field)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)

        // Accept Firestore Timestamp or Date
        if let ts = try? container.decode(Timestamp.self, forKey: .date) {
            self.date = ts.dateValue()
        } else {
            self.date = try container.decode(Date.self, forKey: .date)
        }

        self.time = (try? container.decode(String.self, forKey: .time)) ?? ""
        self.place = (try? container.decode(String.self, forKey: .place)) ?? ""

        let rawMembers = (try? container.decode([String].self, forKey: .members)) ?? []
        self.members = rawMembers.compactMap { QWERMember(rawValue: $0) }
        self.category = ScheduleCategory(rawValue: (try? container.decode(String.self, forKey: .category)) ?? "") ?? .other
    }
}

enum ScheduleCategory: String, Codable, Equatable, CaseIterable {
    case fanSign = "팬사인회"
    case concert = "공연"
    case award = "시상식"
    case birthday = "생일"
    case other = "기타"
}

extension QWERScheduleItem {
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

    var displayTime: String { time.isEmpty ? "시간 미정" : time }
    var displayPlace: String { place.isEmpty ? "장소 미정" : place }
}

// MARK: - QWER 스케줄 모음
extension QWERScheduleItem {
    static var simpleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }
    
    static let schedules: [QWERScheduleItem] = [
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
            place: "예스24 원더로크홀",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "부산 원아시아 페스티벌",
            date: simpleDateFormatter.date(from: "2025-06-12")!,
            time: "18:30",
            place: "BEXCO 제 1전시장",
            members: [.W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "뷰티풀 민트 라이프",
            date: simpleDateFormatter.date(from: "2025-06-13")!,
            time: "18:20",
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
            place: "CJ ENM",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "서울가요대상",
            date: simpleDateFormatter.date(from: "2025-06-21")!,
            time: "18:30",
            place: "인스파이어 아레나",
            members: [.Q, .W, .E, .R],
            category: .award
        ),
        QWERScheduleItem(
            title: "아노블리어 팝업",
            date: simpleDateFormatter.date(from: "2025-06-27")!,
            time: "19:00",
            place: "서울 성동구 상원1길 5 1층",
            members: [.W],
            category: .other
        ),
        QWERScheduleItem(
            title: "위버스 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-28")!,
            time: "20:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-06-29")!,
            time: "18:30",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "더현대닷컴 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-05")!,
            time: "15:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-06")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-12")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-13")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "캐리비안베이 워터뮤직풀파티",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "14:30",
            place: "캐리비안 베이",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-19")!,
            time: "18:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "마이스타굿즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-20")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-26")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-07-27")!,
            time: "17:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "펜타포트 락 페스티벌 2025",
            date: simpleDateFormatter.date(from: "2025-08-01")!,
            time: "13:50",
            place: "송도달빛축제공원",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "비트로드 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-02")!,
            time: "14:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-03")!,
            time: "13:00",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "울산 서머 페스티벌",
            date: simpleDateFormatter.date(from: "2025-08-05")!,
            time: "19:30",
            place: "울산보조경기장 종합운동장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "M COUNTDOWN in Boryeong",
            date: simpleDateFormatter.date(from: "2025-08-07")!,
            time: "18:00",
            place: "대천해수욕장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "케이팝스토어 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-09")!,
            time: "14:00",
            place: "",
            members: [.W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-10")!,
            time: "13:00",
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
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "7rock prime 2025",
            date: simpleDateFormatter.date(from: "2025-08-16")!,
            time: "19:40",
            place: "잠실실내체육관",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "디어마이뮤즈 팬사인회",
            date: simpleDateFormatter.date(from: "2025-08-17")!,
            time: "13:00",
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
            place: "",
            members: [.Q, .W, .E, .R],
            category: .fanSign
        ),
        QWERScheduleItem(
            title: "부산 INTERNATIONAL ROCK FESTIVAL",
            date: simpleDateFormatter.date(from: "2025-09-26")!,
            time: "15:10",
            place: "",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "PMPS SEASON2 FINALS 축하공연",
            date: simpleDateFormatter.date(from: "2025-09-27")!,
            time: "13:00",
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
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-03")!,
            time: "17:00",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-04")!,
            time: "17:00",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR ROCKNATION SEOUL",
            date: simpleDateFormatter.date(from: "2025-10-05")!,
            time: "17:00",
            place: "올림픽 핸드볼 경기장",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "THE HYPER DAY 2025 DAEGU",
            date: simpleDateFormatter.date(from: "2025-10-11")!,
            time: "12:00",
            place: "대구스타디움 동편 메인광장",
            members: [.Q, .W, .E, .R],
            category: .concert
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
            title: "WORLD TOUR BROOKLYN",
            date: simpleDateFormatter.date(from: "2025-10-31")!,
            time: "",
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
            date: simpleDateFormatter.date(from: "2025-11-02")!,
            time: "",
            place: "Terminal West",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR BERWYN",
            date: simpleDateFormatter.date(from: "2025-11-05")!,
            time: "",
            place: "Distro Music Hall",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR MINNEAPOLIS",
            date: simpleDateFormatter.date(from: "2025-11-07")!,
            time: "",
            place: "The Lyric at Skyway Theatre",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR FORT WORTH",
            date: simpleDateFormatter.date(from: "2025-11-11")!,
            time: "",
            place: "Ridglea Theater",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR HOUSTON",
            date: simpleDateFormatter.date(from: "2025-11-12")!,
            time: "",
            place: "Warehouse Live",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR SAN FRANCISCO",
            date: simpleDateFormatter.date(from: "2025-11-14")!,
            time: "",
            place: "Cowell Theater",
            members: [.Q, .W, .E, .R],
            category: .concert
        ),
        QWERScheduleItem(
            title: "WORLD TOUR LOS ANGELES",
            date: simpleDateFormatter.date(from: "2025-11-16")!,
            time: "",
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
            title: "WORLD TOUR HONG KONG",
            date: simpleDateFormatter.date(from: "2026-02-08")!,
            time: "",
            place: "AsiaWorld-Expo, Runway 11",
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
    ]
}

