//
//  SchedulableProtocol.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/26/25.
//

import Foundation

/// 스케줄 아이템 프로토콜
protocol SchedulableItem: Identifiable, Codable {
    var id: UUID { get }
    /// 스케줄명
    var title: String { get set }
    /// 날짜
    var date: Date { get set }
    /// 시간
    var time: String { get set }
    /// 장소
    var place: String { get set }
}

protocol ScheduleServiceProtocol {
    associatedtype Schedule: SchedulableItem
    
    /// 스케줄 생성
    func saveSchedule(_ schedule: Schedule)
    /// 스케줄 수정
    func updateSchedule(_ schedule: Schedule)
    /// 스케줄 삭제
    func deleteSchedule(_ schedule: Schedule)
    /// 스케줄 읽기(FireStore or UserDefaults)
    func fetchSchedule() async throws -> [Schedule]
}
