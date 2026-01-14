//
//  YouTubeAPIRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// YouTube API-backed remote data source.
public struct YouTubeAPIRemoteDataSource: YouTubeRemoteDataSource {
    private let apiClient: YouTubeAPIClient

    public init() {
        self.apiClient = YouTubeAPIClient()
    }

    init(apiClient: YouTubeAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO {
        try await apiClient.fetchVideos(pageToken: pageToken, pageSize: pageSize)
    }

    public func fetchChannelInfo() async throws -> YouTubeChannelDTO {
        try await apiClient.fetchChannelInfo()
    }
}
