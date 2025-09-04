//
//  WindowAlertHostingView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/1/25.
//

import SwiftUI

struct WindowAlertHostingView: View {
    static var AlertNotificationName: Notification.Name {
        .init("RockCrabCalendar.WindowAlertHosting.NetworkError.Name")
    }
    static var AlertDismissNotificationName: Notification.Name {
        .init("RockCrabCalendar.Hosting.NetworkErrorDismiss.Name")
    }
    @State private var error: Error? = nil
    @State private var isPresented: Bool = false
    
    var body: some View {
        Group {
            if isPresented {
                windowView
            } else {
                EmptyView()
            }
        }
        .frame(width: 0, height: 0)
        .onReceive(NotificationCenter.default.publisher(for: Self.AlertNotificationName)
            .map(\.object)
            .compactMap { $0 as? Error }
            .receive(on: DispatchQueue.main)
        ) { error in
            self.error = error
            self.isPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Self.AlertDismissNotificationName)
            .receive(on: DispatchQueue.main)
        ) { _ in
            self.isPresented = false
            self.error = nil
        }
    }
    
    @ViewBuilder
    private var windowView: some View {
        WindowOverlayView(level: UIWindow.Level.normal.rawValue + 0.2, isHidden: false) {
            Spacer()
                .alert(error?.localizedDescription ?? "", isPresented: $isPresented) {
                    return EmptyView()
                }
        }
    }
}
