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

    public init(
        id: String,
        title: String,
        description: String,
        publishedAt: Date?,
        channelTitle: String,
        thumbnailURL: URL?,
        channelId: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.publishedAt = publishedAt
        self.channelTitle = channelTitle
        self.thumbnailURL = thumbnailURL
        self.channelId = channelId
    }
}
