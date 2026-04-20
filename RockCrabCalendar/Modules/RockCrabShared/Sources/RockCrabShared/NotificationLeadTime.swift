import Foundation

public enum NotificationLeadTime: Int, CaseIterable, Codable, Identifiable {
    case oneHour = 3600
    case thirtyMinutes = 1800
    case tenMinutes = 600
    case fiveMinutes = 300

    public var id: Int { rawValue }

    public var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }

    public var displayText: String {
        switch self {
        case .oneHour:
            return AppLocalization.string("1시간 전")
        case .thirtyMinutes:
            return AppLocalization.string("30분 전")
        case .tenMinutes:
            return AppLocalization.string("10분 전")
        case .fiveMinutes:
            return AppLocalization.string("5분 전")
        }
    }

    public static let defaultValue: NotificationLeadTime = .tenMinutes
}
