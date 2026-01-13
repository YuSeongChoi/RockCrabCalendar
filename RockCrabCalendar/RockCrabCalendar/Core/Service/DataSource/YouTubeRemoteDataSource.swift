//
//  YouTubeRemoteDataSource.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Remote data source contract for YouTube endpoints.
protocol YouTubeRemoteDataSource {
    func fetchVideos(pageToken: String?, pageSize: Int) async throws -> YouTubeSearchListDTO
    func fetchChannelInfo() async throws -> YouTubeChannelDTO
}
