//
//  YouTubeVideo.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation

public struct YouTubeVideo: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let publishedAt: Date?
    public let channelTitle: String
    public let thumbnailURL: URL?
    public let channelId: String
}
