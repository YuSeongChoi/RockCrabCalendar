//
//  YouTubeRepository.swift
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
