import Foundation

extension Notification.Name {
    /// Posted whenever schedules are created, updated, or deleted so views can refresh.
    static let schedulesDidChange = Notification.Name("SchedulesDidChange")

    /// Posted when a local QWER schedule (UserDefaults-backed) is created, updated, or deleted.
    static let qwerLocalDidChange = Notification.Name("QWERLocalDidChange")

    /// Posted when a user schedule (UserDefaults-backed) is created, updated, or deleted.
    static let userSchedulesDidChange = Notification.Name("UserSchedulesDidChange")
}
