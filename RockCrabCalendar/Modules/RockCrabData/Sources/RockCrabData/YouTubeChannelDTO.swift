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

    public init(kind: String, etag: String, pageInfo: PageInfoDTO, items: [YouTubeChannelItemDTO]) {
        self.kind = kind
        self.etag = etag
        self.pageInfo = pageInfo
        self.items = items
    }
}

public struct YouTubeChannelItemDTO: Codable {
    public let kind: String
    public let etag: String
    public let id: String
    public let snippet: YouTubeChannelSnippetDTO

    public init(kind: String, etag: String, id: String, snippet: YouTubeChannelSnippetDTO) {
        self.kind = kind
        self.etag = etag
        self.id = id
        self.snippet = snippet
    }
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

    public init(
        title: String,
        description: String,
        customUrl: String,
        publishedAt: String,
        thumbnails: YouTubeThumbnailsDTO,
        localized: YouTubeChannelLocalizedDTO,
        country: String
    ) {
        self.title = title
        self.description = description
        self.customUrl = customUrl
        self.publishedAt = publishedAt
        self.thumbnails = thumbnails
        self.localized = localized
        self.country = country
    }
}

/// 유튜브 채널 로컬라이즈 정보
public struct YouTubeChannelLocalizedDTO: Codable {
    public let title: String
    public let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
