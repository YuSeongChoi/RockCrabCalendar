//
//  YouTubeMapperTests.swift
//  RockCrabCalendarUnitTests
//
//  Created by Codex on 2024/11/24.
//

import XCTest
@testable import RockCrabCalendar
import RockCrabData

final class YouTubeMapperTests: XCTestCase {
    func testThumbnailPriorityHighOverDefault() throws {
        let dto = YouTubeSearchListDTO(
            kind: "youtube#searchListResponse",
            etag: "etag",
            nextPageToken: nil,
            prevPageToken: nil,
            regionCode: "KR",
            pageInfo: .init(totalResults: 1, resultsPerPage: 1),
            items: [
                .init(
                    kind: "youtube#searchResult",
                    etag: "etag",
                    id: .init(kind: "youtube#video", videoId: "vid1", playlistId: nil, channelId: nil),
                    snippet: .init(
                        publishedAt: "2024-01-01T00:00:00Z",
                        channelId: "ch1",
                        title: "title",
                        description: "desc",
                        thumbnails: .init(
                            default: .init(url: "https://default.jpg", width: nil, height: nil),
                            medium: nil,
                            high: .init(url: "https://high.jpg", width: nil, height: nil)
                        ),
                        channelTitle: "channel",
                        liveBroadcastContent: "none",
                        publishTime: "2024-01-01T00:00:00Z"
                    )
                )
            ]
        )
        
        let (videos, token) = YouTubeSearchMapper.map(dto)
        XCTAssertNil(token)
        XCTAssertEqual(videos.count, 1)
        XCTAssertEqual(videos.first?.thumbnailURL?.absoluteString, "https://high.jpg")
    }
    
    func testNextPageTokenNilWhenMissing() throws {
        let dto = YouTubeSearchListDTO(
            kind: "youtube#searchListResponse",
            etag: "etag",
            nextPageToken: nil,
            prevPageToken: nil,
            regionCode: "KR",
            pageInfo: .init(totalResults: 0, resultsPerPage: 0),
            items: []
        )
        
        let (videos, token) = YouTubeSearchMapper.map(dto)
        XCTAssertTrue(videos.isEmpty)
        XCTAssertNil(token)
    }
}
