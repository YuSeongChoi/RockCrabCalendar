//
//  YouTubeUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import Foundation

public struct YouTubeSearchResult: Equatable {
    public let videos: [YouTubeVideo]
    public let nextPageToken: String?

    public init(videos: [YouTubeVideo], nextPageToken: String?) {
        self.videos = videos
        self.nextPageToken = nextPageToken
    }
}

public struct YouTubeChannelInfo: Equatable {
    public let thumbnailURL: URL?

    public init(thumbnailURL: URL?) {
        self.thumbnailURL = thumbnailURL
    }
}

// Repository abstraction for YouTube access to enable DI and testing.
public protocol YouTubeRepository {
    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchResult
    func fetchChannelInfo() async throws -> YouTubeChannelInfo
}

// Use-case layer for YouTube list/channel info.
public struct YouTubeUseCase {
    private let repository: YouTubeRepository

    public init(repository: YouTubeRepository) {
        self.repository = repository
    }

    public func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchResult {
        try await repository.fetchVideos(pageToken: pageToken, pageSize: pageSize)
    }

    public func fetchChannelInfo() async throws -> YouTubeChannelInfo {
        try await repository.fetchChannelInfo()
    }
}
