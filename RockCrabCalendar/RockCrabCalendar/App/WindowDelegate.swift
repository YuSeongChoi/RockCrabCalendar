//
//  WindowDelegate.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import UIKit

@MainActor
final class WindowDelegate: NSObject, UIWindowSceneDelegate, ObservableObject, Identifiable {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = windowScene.keyWindow
        let outTapGesture = UITapGestureRecognizer(target: self, action: #selector(dropInputResponder(_:)))
        outTapGesture.cancelsTouchesInView = false
        outTapGesture.requiresExclusiveTouchType = true
        window?.addGestureRecognizer(outTapGesture)
    }
    
    @objc
    private func dropInputResponder(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            sender.view?.endEditing(true)
        default:
            break
        }
    }
}
