//
//  NotificationManager.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 12/4/25.
//

import Foundation
import UserNotifications
import RockCrabDomain
import RockCrabShared

protocol NotificationScheduling {
    func schedule<T: SchedulableItemProtocol>(for schedule: T, offsets: [TimeInterval])
    func cancel<T: SchedulableItemProtocol>(for schedule: T, offsets: [TimeInterval])
}

extension NotificationScheduling {
    func schedule<T: SchedulableItemProtocol>(for item: T) {
        self.schedule(for: item, offsets: [300, 600])
    }

    func cancel<T: SchedulableItemProtocol>(for item: T) {
        self.cancel(for: item, offsets: [300, 600])
    }
}

/// 로컬 알림을 관리하는 매니저
/// - 사용 예: 앱 시작 시 권한 요청 → 일정 생성/수정 시 예약, 삭제 시 취소
final class NotificationManager: NotificationScheduling {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// 알림 권한 요청 (앱 시작 시 1회 호출 권장)
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            #if DEBUG
            AppLogger.error("Notification auth error: \(error.localizedDescription)", category: .notification)
            #endif
            return false
        }
    }

    /// 일정 알림 예약 (기본 5분/10분 전)
    /// - Parameters:
    ///   - schedule: `SchedulableItemProtocol`을 따르는 일정 모델
    ///   - offsets: 알림을 울릴 시간(초) 배열. 기본값은 300초(5분), 600초(10분)
    func schedule<T: SchedulableItemProtocol>(
        for schedule: T,
        offsets: [TimeInterval] = [300, 600]
    ) {
        guard schedule.shouldNotify else {
            #if DEBUG
            AppLogger.debug("\(schedule.title): 알림 비활성화됨", category: .notification)
            #endif
            return
        }
        
        guard let eventDate = buildStartDate(from: schedule) else { return }

        for offset in offsets {
            let fireDate = eventDate.addingTimeInterval(-offset)
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "곧 일정 시작"
            content.body = "\(schedule.title)이(가) \(Int(offset / 60))분 후 시작돼요!"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(for: schedule.id, offset: offset),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// 예약된 일정 알림 취소 (수정/삭제 시 사용)
    func cancel<T: SchedulableItemProtocol>(
        for schedule: T,
        offsets: [TimeInterval] = [300, 600]
    ) {
        let ids = offsets.map { notificationID(for: schedule.id, offset: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - 내부 헬퍼
extension NotificationManager {
    func notificationID(for id: UUID, offset: TimeInterval) -> String {
        "\(id.uuidString)-\(Int(offset))"
    }

    /// 날짜(Date)와 시간(startTime)을 합쳐 알림 기준 Date를 만든다.
    func buildStartDate(from schedule: some SchedulableItemProtocol) -> Date? {
        let calendar = Calendar.current

        if schedule.isAllDay {
            return calendar.startOfDay(for: schedule.date)
        }

        if let start = schedule.startTime {
            let timeComps = calendar.dateComponents([.hour, .minute, .second], from: start)
            var dateComps = calendar.dateComponents([.year, .month, .day], from: schedule.date)
            dateComps.hour = timeComps.hour
            dateComps.minute = timeComps.minute
            dateComps.second = timeComps.second ?? 0
            return calendar.date(from: dateComps)
        }

        // startTime이 없으면 date 자체를 사용 (예: legacy time 필드만 있는 경우)
        return schedule.date
    }
}
