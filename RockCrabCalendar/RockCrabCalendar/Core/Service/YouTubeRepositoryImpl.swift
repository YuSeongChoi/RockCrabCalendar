//
//  YouTubeRepositoryImpl.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Concrete repository using a remote data source (Data layer).
struct YouTubeRepositoryImpl: YouTubeRepository {
    private let remote: YouTubeRemoteDataSource

     // Inject remote data source for testability.
    init(remote: YouTubeRemoteDataSource = YouTubeAPIRemoteDataSource()) {
        self.remote = remote
    }

    // Fetch video list DTO from the API.
    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO {
        try await remote.fetchVideos(pageToken: pageToken, pageSize: pageSize)
    }

    // Fetch channel info DTO from the API.
    func fetchChannelInfo() async throws -> YouTubeChannelDTO {
        try await remote.fetchChannelInfo()
    }
}
