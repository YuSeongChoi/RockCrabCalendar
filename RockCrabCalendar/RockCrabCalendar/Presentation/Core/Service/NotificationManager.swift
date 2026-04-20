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

enum NotificationAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized

    var isAuthorized: Bool {
        self == .authorized
    }

    var summaryText: String {
        switch self {
        case .authorized:
            return AppLocalization.string("알림이 켜져 있어요")
        case .denied:
            return AppLocalization.string("기기 설정에서 알림이 꺼져 있어요")
        case .notDetermined:
            return AppLocalization.string("알림 권한이 아직 정해지지 않았어요")
        }
    }

    var detailText: String {
        switch self {
        case .authorized:
            return AppLocalization.string("일정 알림을 받을 수 있습니다.")
        case .denied:
            return AppLocalization.string("설정 앱에서 알림을 켜야 일정 시작 전에 안내를 받을 수 있어요.")
        case .notDetermined:
            return AppLocalization.string("알림 권한이 없으면 저장해도 알림이 오지 않을 수 있어요.")
        }
    }
}

enum NotificationAvailability: Equatable {
    case disabled
    case available
    case denied
    case notDetermined
    case allDay
    case timeUnspecified
    case pastEvent

    var message: String? {
        switch self {
        case .disabled:
            return nil
        case .available:
            return AppLocalization.string("알림을 켜면 시작 10분 전, 5분 전에 알려드려요.")
        case .denied:
            return AppLocalization.string("현재 기기 설정에서 알림이 꺼져 있어 저장해도 알림이 오지 않아요.")
        case .notDetermined:
            return AppLocalization.string("알림 권한이 아직 정해지지 않아 저장 후 알림이 오지 않을 수 있어요.")
        case .allDay:
            return AppLocalization.string("하루종일 일정은 시작 시각이 없어 알림을 보낼 수 없어요.")
        case .timeUnspecified:
            return AppLocalization.string("시간 미정 일정은 시작 시각이 없어 알림을 보낼 수 없어요.")
        case .pastEvent:
            return AppLocalization.string("이미 지난 시점의 일정이라 알림을 예약하지 않아요.")
        }
    }

    var saveFeedbackMessage: String? {
        switch self {
        case .denied:
            return AppLocalization.string("일정은 저장됐지만 기기 설정에서 알림이 꺼져 있어 알림은 예약되지 않았어요.")
        case .notDetermined:
            return AppLocalization.string("일정은 저장됐지만 알림 권한이 없어 알림이 예약되지 않았을 수 있어요.")
        case .allDay:
            return AppLocalization.string("일정은 저장됐지만 하루종일 일정은 알림을 보낼 수 없어요.")
        case .timeUnspecified:
            return AppLocalization.string("일정은 저장됐지만 시간 미정 일정은 알림을 보낼 수 없어요.")
        case .pastEvent:
            return AppLocalization.string("일정은 저장됐지만 이미 지난 시점이라 알림을 예약하지 않았어요.")
        case .disabled, .available:
            return nil
        }
    }
}

protocol NotificationScheduling {
    func schedule<T: SchedulableItemProtocol>(for schedule: T, offsets: [TimeInterval])
    func cancel<T: SchedulableItemProtocol>(for schedule: T, offsets: [TimeInterval])
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func availability<T: SchedulableItemProtocol>(
        for schedule: T,
        authorizationStatus: NotificationAuthorizationStatus
    ) -> NotificationAvailability
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

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
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
            content.title = AppLocalization.string("곧 일정 시작")
            content.body = String.localizedStringWithFormat(
                AppLocalization.string("%@이(가) %lld분 후 시작돼요!"),
                schedule.title,
                Int(offset / 60)
            )
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

    func availability<T: SchedulableItemProtocol>(
        for schedule: T,
        authorizationStatus: NotificationAuthorizationStatus
    ) -> NotificationAvailability {
        guard schedule.shouldNotify else { return .disabled }

        guard authorizationStatus.isAuthorized else {
            return authorizationStatus == .denied ? .denied : .notDetermined
        }

        if schedule.isAllDay {
            return .allDay
        }

        guard schedule.startTime != nil else {
            return .timeUnspecified
        }

        guard let eventDate = buildStartDate(from: schedule), eventDate > Date() else {
            return .pastEvent
        }

        return .available
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
