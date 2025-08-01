//
//  ScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation

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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.time = try container.decode(String.self, forKey: .time)
        self.place = try container.decode(String.self, forKey: .place)
        
        let rawMembers = try container.decode([String].self, forKey: .members)
        self.members = rawMembers.compactMap { QWERMember(rawValue: $0) }
        
        // Generate UUID locally since Firestore doc ID is not being used
        self.id = UUID()
    }
}

//extension ScheduleItem {
//    static let mockSchedules: [ScheduleItem] = [
//        ScheduleItem(
//            title: "QWER 팬사인회",
//            date: Date(),
//            time: "15시",
//            place: "서울 코엑스",
//            members: [.chodan, .magenta, .hina, .siyo]
//        ),
//        ScheduleItem(
//            title: "QWER 쇼케이스",
//            date: Date().addDay(n: 7),
//            time: "19시",
//            place: "서울 코엑스",
//            members: [.chodan, .magenta, .hina, .siyo]
//        ),
//        ScheduleItem(
//            title: "마운틴듀 팝업",
//            date: Date().addDay(n: 3),
//            time: "11시",
//            place: "판교",
//            members: [.hina, .siyo]
//        ),
//        ScheduleItem(
//            title: "라이엇 팝업",
//            date: Date().addDay(n: -8),
//            time: "11시",
//            place: "홍대",
//            members: [.chodan, .magenta]
//        )
//    ]
//}
