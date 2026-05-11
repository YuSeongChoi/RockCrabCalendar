//
//  InterstitialAdService.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/05/06.
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
@Observable
final class InterstitialAdService: NSObject {
    private let adUnitID: String
    private var interstitialAd: InterstitialAd?
    private var isLoading = false

    init(adUnitID: String = AdConfiguration.interstitialAdUnitID) {
        self.adUnitID = adUnitID
        super.init()
    }

    func preload() async {
        guard interstitialAd == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await InterstitialAd.load(with: adUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            interstitialAd = ad
        } catch {
            interstitialAd = nil
        }
    }

    @discardableResult
    func presentIfReady() async -> Bool {
        guard let rootViewController = UIApplication.shared.topMostViewController() else {
            await preload()
            return false
        }

        guard let interstitialAd else {
            await preload()
            return false
        }

        self.interstitialAd = nil
        interstitialAd.present(from: rootViewController)
        return true
    }
}

extension InterstitialAdService: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            await preload()
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            await preload()
        }
    }
}

extension UIApplication {
    @MainActor
    func topMostViewController() -> UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostPresentedViewController()
    }
}

private extension UIViewController {
    @MainActor
    func topMostPresentedViewController() -> UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostPresentedViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostPresentedViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostPresentedViewController() ?? tabBarController
        }
        return self
    }
}
