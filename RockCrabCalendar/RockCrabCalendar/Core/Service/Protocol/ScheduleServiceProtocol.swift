//
//  ScheduleServiceProtocol.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 10/17/25.
//

import Foundation

protocol ScheduleServiceProtocol {
    associatedtype Schedule: SchedulableItemProtocol
    
    /// 스케줄 생성
    func saveSchedule(_ schedule: Schedule)
    /// 스케줄 수정
    func updateSchedule(_ schedule: Schedule)
    /// 스케줄 삭제
    func deleteSchedule(_ schedule: Schedule)
    /// 스케줄 읽기(FireStore or UserDefaults)
    func fetchSchedule() async throws -> [Schedule]
}
