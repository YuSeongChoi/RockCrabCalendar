//
//  Bundle+Extension.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 8/27/25.
//

import Foundation

extension Bundle {
    var youtubeAPIKey: String {
        guard let key = infoDictionary?["YouTubeAPIKey"] as? String else {
            fatalError("❌ Info.plist에 YouTubeAPIKey가 없습니다.")
        }
        return key
    }
}
