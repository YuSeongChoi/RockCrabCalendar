//
//  Bundle+Extension.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 8/27/25.
//

import Foundation

extension Bundle {
    /// Info.plist에서 특정 Key의 값을 가져오는 범용 함수
    func value(for key: String) -> String {
        guard let value = infoDictionary?[key] as? String, !value.isEmpty else {
            debugPrint("❌ Info.plist에 \(key) 값이 없습니다.")
            return ""
        }
        return value
    }
    
    /// YouTube API Key
    var youtubeAPIKey: String {
        value(for: "YouTubeAPIKey")
    }
    
    /// QWER 채널 ID
    var qwerChannelID: String {
        value(for: "QWERChannelID")
    }
    
    /// 만약 서버 BaseURL 같은 게 필요하다면
    var serverBaseURL: String {
        value(for: "ServerBaseURL")
    }
}
