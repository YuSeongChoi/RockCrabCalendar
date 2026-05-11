//
//  AdConfiguration.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/05/06.
//

import Foundation

enum AdConfiguration {
    static let appID = "ca-app-pub-4795000952052288~4177969641"
    static let removeAdsProductID = "rockcrabcalendar.remove_ads"
    static let interstitialTriggerCount = 5

    static var bannerAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2435281174"
        #else
        return "ca-app-pub-4795000952052288/1876074083"
        #endif
    }

    static var interstitialAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        return "ca-app-pub-4795000952052288/5463965306"
        #endif
    }
}
