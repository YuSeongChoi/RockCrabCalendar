//
//  ScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation

enum QWERMember: String, CaseIterable {
    case chodan, magenta, hina, siyo
}

struct ScheduleItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let time: String
    let place: String
    let members: [QWERMember]
}

extension ScheduleItem {
    static let mockSchedules: [ScheduleItem] = [
        ScheduleItem(
            title: "QWER 팬사인회",
            date: Date(),
            time: "15시",
            place: "서울 코엑스",
            members: [.chodan, .magenta, .hina, .siyo]
        ),
        ScheduleItem(
            title: "QWER 쇼케이스",
            date: Date().addDay(n: 7),
            time: "19시",
            place: "서울 코엑스",
            members: [.chodan, .magenta, .hina, .siyo]
        ),
        ScheduleItem(
            title: "마운틴듀 팝업",
            date: Date().addDay(n: 3),
            time: "11시",
            place: "판교",
            members: [.hina, .siyo]
        ),
        ScheduleItem(
            title: "라이엇 팝업",
            date: Date().addDay(n: -8),
            time: "11시",
            place: "홍대",
            members: [.chodan, .magenta]
        )
    ]
}
