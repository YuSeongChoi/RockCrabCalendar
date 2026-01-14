//
//  YouTubeRepositoryImpl.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import RockCrabDomain

// Concrete repository using a remote data source (Data layer).
public struct YouTubeRepositoryImpl: YouTubeRepository {
    private let remote: YouTubeRemoteDataSource

     // Inject remote data source for testability.
    public init(remote: YouTubeRemoteDataSource = YouTubeAPIRemoteDataSource()) {
        self.remote = remote
    }

    // Fetch video list and map to domain.
    public func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchResult {
        let dto = try await remote.fetchVideos(pageToken: pageToken, pageSize: pageSize)
        let mapped = YouTubeSearchMapper.map(dto)
        return YouTubeSearchResult(videos: mapped.videos, nextPageToken: mapped.nextPageToken)
    }

    // Fetch channel info and map to domain.
    public func fetchChannelInfo() async throws -> YouTubeChannelInfo {
        let dto = try await remote.fetchChannelInfo()
        let urlString =
        dto.items.first?.snippet.thumbnails.default?.url ??
        dto.items.first?.snippet.thumbnails.medium?.url ??
        dto.items.first?.snippet.thumbnails.high?.url
        return YouTubeChannelInfo(thumbnailURL: urlString.flatMap(URL.init(string:)))
    }
}
