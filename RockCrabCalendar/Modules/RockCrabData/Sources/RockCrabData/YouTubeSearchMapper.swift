//
//  YouTubeSearchMapper.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation
import RockCrabDomain

public enum YouTubeSearchMapper {
    // Search 리스트 DTO -> [YouTubeVideo]
    public static func map(_ dto: YouTubeSearchListDTO) -> (videos: [YouTubeVideo], nextPageToken: String?) {
        let videos: [YouTubeVideo] = dto.items.compactMap { (item) -> YouTubeVideo? in
            // 비디오면 필터
            guard item.id.kind == "youtube#video", let videoId = item.id.videoId else { return nil }
            
            let snippet = item.snippet
            // 썸네일 고르기 (high -> medium -> default)
            let thumbURLString = snippet.thumbnails.high?.url
            ?? snippet.thumbnails.medium?.url
            ?? snippet.thumbnails.default?.url
            
            let date = YouTubeDateParser.parse(snippet.publishedAt) ?? YouTubeDateParser.parse(snippet.publishTime)
            let url = thumbURLString.flatMap(URL.init(string:))
            
            return YouTubeVideo(
                id: videoId,
                title: snippet.title,
                description: snippet.description,
                publishedAt: date,
                channelTitle: snippet.channelTitle,
                thumbnailURL: url,
                channelId: snippet.channelId
            )
        }
        
        return (videos, dto.nextPageToken)
    }
}
