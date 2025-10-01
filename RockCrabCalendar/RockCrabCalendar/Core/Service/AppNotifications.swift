import Foundation

extension Notification.Name {
    /// Posted whenever schedules are created, updated, or deleted so views can refresh.
    static let schedulesDidChange = Notification.Name("SchedulesDidChange")
}
