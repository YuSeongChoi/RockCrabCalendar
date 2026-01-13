//
//  YouTubeUseCase.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Repository abstraction for YouTube access to enable DI and testing.
protocol YouTubeRepository {
    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO
    func fetchChannelInfo() async throws -> YouTubeChannelDTO
}

// Use-case layer for YouTube, returning domain models to the ViewModel.
struct YouTubeUseCase {
    private let repository: YouTubeRepository

    // Compose with a repository (API client, mock, etc).
    init(repository: YouTubeRepository) {
        self.repository = repository
    }

    // Fetch a page of videos and map to domain models.
    func fetchVideoPage(pageToken: String?, pageSize: Int = 10) async throws -> (videos: [YouTubeVideo], nextPageToken: String?) {
        let dto = try await repository.fetchVideos(pageToken: pageToken, pageSize: pageSize)
        let mapped = YouTubeSearchMapper.map(dto)
        return (mapped.videos, mapped.nextPageToken)
    }

    // Fetch the channel thumbnail URL if available.
    func fetchChannelThumbnailURL() async throws -> URL? {
        let dto = try await repository.fetchChannelInfo()
        let urlString =
        dto.items.first?.snippet.thumbnails.default?.url ??
        dto.items.first?.snippet.thumbnails.medium?.url ??
        dto.items.first?.snippet.thumbnails.high?.url
        return urlString.flatMap(URL.init(string:))
    }
}
