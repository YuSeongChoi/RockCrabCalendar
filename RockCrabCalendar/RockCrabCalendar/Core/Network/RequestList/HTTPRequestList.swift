//
//  HTTPRequestList.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/4/25.
//

import Foundation
import Alamofire

public enum HTTPRequestList {}

extension HTTPRequestList {
    // MARK: 채널 리스트 조회
    struct ChannelListRequest: DataRequestFormProtocol, Encodable {
        var path: String { "search" }
        var method: HTTPMethod { .get }
        var validation: DataRequest.Validation? { nil }
        let key: String
        let channelId: String
        let maxResults: Int
        let pageToken: String?

        // Fixed params
        let part = "snippet"
        let order = "date"
        let type = "video"

        // GET 쿼리로 붙일 파라미터 (빈 값 방지 + 정규화)
        var parameters: Parameters? {
            return [
                "key": key,
                "channelId": channelId,
                "part": part,
                "order": order,
                "maxResults": maxResults,
                "type": type
            ]
        }

        // 반드시 queryString로!
        var encoding: ParameterEncoding { URLEncoding.queryString }
    }
}
