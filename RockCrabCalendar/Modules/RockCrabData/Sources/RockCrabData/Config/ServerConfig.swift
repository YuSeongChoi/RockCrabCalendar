//
//  ServerConfig.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/1/25.
//

import Foundation
import RockCrabShared
let ServerConstant: ServerConfiguration = {
    let config: ServerConfiguration
    config = .Youtube
    return config
}()

let API_KEY = Bundle.main.youtubeAPIKey
let CHANNEL_ID = Bundle.main.qwerChannelID
let HOLIDAY_API_KEY = Bundle.main.holidayAPIKey

struct ServerConfiguration: Hashable, Sendable {
    var baseURL: String
}

extension ServerConfiguration {
    static var Youtube: Self {
        .init(baseURL: "https://www.googleapis.com/youtube/v3")
    }
}
