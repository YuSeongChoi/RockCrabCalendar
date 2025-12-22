//
//  YouTubeAPIClient.swift
//  RockCrabCalendar
//
//  API client for YouTube endpoints.
//

import Foundation

struct YouTubeAPIClient {
    private let apiKey: String
    private let channelId: String

    init(apiKey: String = API_KEY, channelId: String = CHANNEL_ID) {
        self.apiKey = apiKey
        self.channelId = channelId
    }

    func fetchVideos(pageToken: String?, pageSize: Int = 10) async throws -> YouTubeSearchListDTO {
        let request = HTTPRequestList.ChannelListRequest(
            key: apiKey,
            channelId: channelId,
            maxResults: pageSize,
            pageToken: pageToken
        )

        return try await request
            .buildDataRequest()
            .serializingDecodable(YouTubeSearchListDTO.self, automaticallyCancelling: true)
            .result
            .mapError { $0.underlyingError ?? $0 }
            .get()
    }

    func fetchChannelInfo() async throws -> YouTubeChannelDTO {
        try await HTTPRequestList.ChannelInfoRequest()
            .buildDataRequest()
            .serializingDecodable(YouTubeChannelDTO.self, automaticallyCancelling: true)
            .result
            .mapError { $0.underlyingError ?? $0 }
            .get()
    }
}
