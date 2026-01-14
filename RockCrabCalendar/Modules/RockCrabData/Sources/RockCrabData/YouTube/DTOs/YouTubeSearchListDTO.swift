//
//  YouTubeSearchListDTO.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation


/// 유튜브 리스트 목록
public struct YouTubeSearchListDTO: Codable {
    public let kind: String
    public let etag: String
    public let nextPageToken: String?
    public let prevPageToken: String?
    public let regionCode: String?
    public let pageInfo: PageInfoDTO
    public let items: [YouTubeSearchItemDTO]

    public init(
        kind: String,
        etag: String,
        nextPageToken: String?,
        prevPageToken: String?,
        regionCode: String?,
        pageInfo: PageInfoDTO,
        items: [YouTubeSearchItemDTO]
    ) {
        self.kind = kind
        self.etag = etag
        self.nextPageToken = nextPageToken
        self.prevPageToken = prevPageToken
        self.regionCode = regionCode
        self.pageInfo = pageInfo
        self.items = items
    }
}

public struct PageInfoDTO: Codable {
    public let totalResults: Int
    public let resultsPerPage: Int

    public init(totalResults: Int, resultsPerPage: Int) {
        self.totalResults = totalResults
        self.resultsPerPage = resultsPerPage
    }
}

/// 개별 아이템
public struct YouTubeSearchItemDTO: Codable {
    public let kind: String
    public let etag: String
    public let id: YouTubeSearchIdDTO
    public let snippet: YouTubeSnippetDTO

    public init(kind: String, etag: String, id: YouTubeSearchIdDTO, snippet: YouTubeSnippetDTO) {
        self.kind = kind
        self.etag = etag
        self.id = id
        self.snippet = snippet
    }
}

public struct YouTubeSearchIdDTO: Codable {
    public let kind: String
    public let videoId: String?
    public let playlistId: String?
    public let channelId: String?

    public init(kind: String, videoId: String?, playlistId: String?, channelId: String?) {
        self.kind = kind
        self.videoId = videoId
        self.playlistId = playlistId
        self.channelId = channelId
    }
}

/// 메타 정보
public struct YouTubeSnippetDTO: Codable {
    public let publishedAt: String // 날짜는 문자열로 받고 매퍼에서 Date로 변환
    public let channelId: String
    public let title: String
    public let description: String
    public let thumbnails: YouTubeThumbnailsDTO
    public let channelTitle: String
    public let liveBroadcastContent: String?
    public let publishTime: String?

    public init(
        publishedAt: String,
        channelId: String,
        title: String,
        description: String,
        thumbnails: YouTubeThumbnailsDTO,
        channelTitle: String,
        liveBroadcastContent: String?,
        publishTime: String?
    ) {
        self.publishedAt = publishedAt
        self.channelId = channelId
        self.title = title
        self.description = description
        self.thumbnails = thumbnails
        self.channelTitle = channelTitle
        self.liveBroadcastContent = liveBroadcastContent
        self.publishTime = publishTime
    }
}

public struct YouTubeThumbnailsDTO: Codable {
    public let `default`: YouTubeThumbnailDTO?
    public let medium: YouTubeThumbnailDTO?
    public let high: YouTubeThumbnailDTO?

    public init(default: YouTubeThumbnailDTO?, medium: YouTubeThumbnailDTO?, high: YouTubeThumbnailDTO?) {
        self.`default` = `default`
        self.medium = medium
        self.high = high
    }
}

public struct YouTubeThumbnailDTO: Codable {
    public let url: String
    public let width: Int?
    public let height: Int?

    public init(url: String, width: Int?, height: Int?) {
        self.url = url
        self.width = width
        self.height = height
    }
}
