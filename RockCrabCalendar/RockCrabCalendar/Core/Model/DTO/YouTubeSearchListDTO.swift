//
//  YouTubeSearchListDTO.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation


// 최상위 응답
public struct YouTubeSearchListDTO: Codable {
    public let kind: String
    public let etag: String
    public let nextPageToken: String?
    public let prevPageToken: String?
    public let regionCode: String?
    public let pageInfo: PageInfoDTO
    public let items: [YouTubeSearchItemDTO]
}

public struct PageInfoDTO: Codable {
    public let totalResults: Int
    public let resultsPerPage: Int
}

// 개별 아이템
public struct YouTubeSearchItemDTO: Codable {
    public let kind: String
    public let etag: String
    public let id: YouTubeSearchIdDTO
    public let snippet: YouTubeSnippetDTO
}

public struct YouTubeSearchIdDTO: Codable {
    public let kind: String
    public let videoId: String?
    public let playlistId: String?
    public let channelId: String?
}

// 메타 정보
public struct YouTubeSnippetDTO: Codable {
    public let publishedAt: String // 날짜는 문자열로 받고 매퍼에서 Date로 변환
    public let channelId: String
    public let title: String
    public let description: String
    public let thumbnails: YouTubeThumbnailsDTO
    public let channelTitle: String
    public let liveBroadcastContent: String?
    public let publishTime: String?
}

public struct YouTubeThumbnailsDTO: Codable {
    public let `default`: YouTubeThumbnailDTO?
    public let medium: YouTubeThumbnailDTO?
    public let high: YouTubeThumbnailDTO?
}

public struct YouTubeThumbnailDTO: Codable {
    public let url: String
    public let width: Int?
    public let height: Int?
}
