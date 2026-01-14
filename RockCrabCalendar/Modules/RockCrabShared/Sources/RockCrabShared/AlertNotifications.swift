//
//  AlertNotifications.swift
//  RockCrabCalendar
//
//  Shared notification names for network error overlays.
//

import Foundation

public enum AlertNotificationName {
    public static let networkError = Notification.Name("RockCrabCalendar.WindowAlertHosting.NetworkError.Name")
    public static let networkErrorDismiss = Notification.Name("RockCrabCalendar.Hosting.NetworkErrorDismiss.Name")
}
