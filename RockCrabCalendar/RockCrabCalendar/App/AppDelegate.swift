//
//  AppDelegate.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject, Identifiable {
    @Published var showIndicator = true
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = connectingSceneSession.configuration.copy() as! UISceneConfiguration
        switch connectingSceneSession.role {
        case .windowApplication:
            configuration.delegateClass = WindowDelegate.self
        case .windowExternalDisplayNonInteractive:
            fallthrough
        default:
            break
        }
        return configuration
    }
}
