//
//  YouTubeAPIRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// YouTube API-backed remote data source.
struct YouTubeAPIRemoteDataSource: YouTubeRemoteDataSource {
    private let apiClient: YouTubeAPIClient

    init(apiClient: YouTubeAPIClient = YouTubeAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO {
        try await apiClient.fetchVideos(pageToken: pageToken, pageSize: pageSize)
    }

    func fetchChannelInfo() async throws -> YouTubeChannelDTO {
        try await apiClient.fetchChannelInfo()
    }
}
