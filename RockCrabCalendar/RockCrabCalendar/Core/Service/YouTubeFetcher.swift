//
//  YouTubeFetcher.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 8/27/25.
//


import Foundation

@Observable
class YouTubeFetcher {
    var videos: [YouTubeVideo] = []

    private let apiKey = Bundle.main.youtubeAPIKey
    private let channelId = Bundle.main.qwerChannelID

    func fetchLatestVideos(maxResults: Int = 5) {
        let urlString = """
        https://www.googleapis.com/youtube/v3/search?key=\(apiKey)&channelId=\(channelId)&part=snippet&order=date&maxResults=\(maxResults)&type=video
        """

        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(YouTubeResponse.self, from: data)

                let formatter = ISO8601DateFormatter()
                self.videos = decoded.items.compactMap {
                    if let videoId = $0.id.videoId,
                       let published = formatter.date(from: $0.snippet.publishedAt),
                       let thumbURL = URL(string: $0.snippet.thumbnails.medium.url) {
                        return YouTubeVideo(
                            id: videoId,
                            title: $0.snippet.title,
                            publisedAt: published,
                            thumbnailURL: thumbURL
                        )
                    } else {
                        return nil
                    }
                }
            } catch {
                print("❌ 유튜브 API 오류: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 내부 구조용 Decodable
private struct YouTubeResponse: Codable {
    let items: [YouTubeItem]
}

private struct YouTubeItem: Codable {
    let id: VideoID
    let snippet: Snippet
}

private struct VideoID: Codable {
    let videoId: String?
}

private struct Snippet: Codable {
    let publishedAt: String
    let title: String
    let description: String
    let thumbnails: ThumbnailWrapper
}

private struct ThumbnailWrapper: Codable {
    let medium: Thumbnail
}

private struct Thumbnail: Codable {
    let url: String
}

