//
//  ChannelDTO.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/15/25.
//

import Foundation


/// 유튜브 채널 정보
public struct YouTubeChannelDTO: Codable {
    public let kind: String
    public let etag: String
    public let pageInfo: PageInfoDTO
    public let items: [YouTubeChannelItemDTO]
}

public struct YouTubeChannelItemDTO: Codable {
    public let kind: String
    public let etag: String
    public let id: String
    public let snippet: YouTubeChannelSnippetDTO
}

/// 유튜브 채널 메타 정보
public struct YouTubeChannelSnippetDTO: Codable {
    public let title: String
    public let description: String
    public let customUrl: String
    public let publishedAt: String
    public let thumbnails: YouTubeThumbnailsDTO
    public let localized: YouTubeChannelLocalizedDTO
    public let country: String
}

/// 유튜브 채널 로컬라이즈 정보
public struct YouTubeChannelLocalizedDTO: Codable {
    public let title: String
    public let description: String
}
