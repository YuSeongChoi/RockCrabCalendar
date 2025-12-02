//
//  SchedulableProtocol.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

/// 스케줄 아이템 프로토콜
protocol SchedulableItemProtocol: Identifiable, Codable {
    var id: UUID { get }
    /// 스케줄명
    var title: String { get set }
    /// 날짜
    var date: Date { get set }
    /// 시간
    var time: String { get set }
    /// 하루종일 여부
    var isAllDay: Bool { get set }
    /// 시작 시간
    var startTime: Date? { get set }
    /// 종료 시간
    var endTime: Date? { get set }
    /// 장소
    var place: String { get set }
}
