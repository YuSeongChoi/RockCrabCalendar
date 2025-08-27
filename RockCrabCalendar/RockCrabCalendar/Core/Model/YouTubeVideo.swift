//
//  YouTubeVideo.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 8/27/25.
//

import Foundation

struct YouTubeVideo: Identifiable, Codable {
    let id: String
    let title: String
    let publisedAt: Date
    let thumbnailURL: URL
}
