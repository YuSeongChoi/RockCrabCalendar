//
//  YouTubeRepositoryImpl.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Concrete repository using the API client (Data layer).
struct YouTubeRepositoryImpl: YouTubeRepository {
    private let apiClient: YouTubeAPIClient

    // Inject API client for testability.
    init(apiClient: YouTubeAPIClient = YouTubeAPIClient()) {
        self.apiClient = apiClient
    }

    // Fetch video list DTO from the API.
    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO {
        try await apiClient.fetchVideos(pageToken: pageToken, pageSize: pageSize)
    }

    // Fetch channel info DTO from the API.
    func fetchChannelInfo() async throws -> YouTubeChannelDTO {
        try await apiClient.fetchChannelInfo()
    }
}
