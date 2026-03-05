import XCTest
import RockCrabDomain
@testable import RockCrabData

final class YouTubeDecodingTests: XCTestCase {
    let json = """
                { "kind":"youtube#searchListResponse", "etag":"x",
                  "nextPageToken":"CAUQAA", "regionCode":"KR",
                  "pageInfo":{"totalResults":2,"resultsPerPage":2},
                  "items":[
                    {
                      "kind":"youtube#searchResult","etag":"e1",
                      "id":{"kind":"youtube#video","videoId":"VID_A"},
                      "snippet":{
                        "publishedAt":"2025-06-08T03:00:12Z",
                        "channelId":"CH_A",
                        "title":"TITLE_A","description":"DESC_A",
                        "thumbnails":{"high":{"url":"https://i.ytimg.com/vi/VID_A/hqdefault.jpg"}},
                        "channelTitle":"QWER",
                        "liveBroadcastContent":"none",
                        "publishTime":"2025-06-08T03:00:12Z"
                      }
                    },
                    {
                      "kind":"youtube#searchResult","etag":"e2",
                      "id":{"kind":"youtube#video","videoId":"VID_B"},
                      "snippet":{
                        "publishedAt":"2024-02-18T03:00:27Z",
                        "channelId":"CH_B",
                        "title":"TITLE_B","description":"DESC_B",
                        "thumbnails":{"default":{"url":"https://i.ytimg.com/vi/VID_B/default.jpg"}},
                        "channelTitle":"QWER",
                        "liveBroadcastContent":"none",
                        "publishTime":"2024-02-18T03:00:27Z"
                      }
                    }
                  ]
                }
        """.data(using: .utf8)!

    func testdecodeSample() throws {
        let dto = try JSONDecoder.youtube.decode(YouTubeSearchListDTO.self, from: json)
        let (videos, token) = YouTubeSearchMapper.map(dto)

        XCTAssertEqual(token, "CAUQAA")
        XCTAssertEqual(videos.count, 2)
        XCTAssertEqual(videos.first?.id, "VID_A")
        XCTAssertNotNil(videos.first?.thumbnailURL)
        XCTAssertEqual(videos.first?.channelTitle, "QWER")
    }
}
