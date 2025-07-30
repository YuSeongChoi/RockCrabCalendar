//
//  ScheduleItem.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import Foundation

struct ScheduleItem: Identifiable {
    let id = UUID()
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
