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
    // MARK: 공휴일 조회
    struct HolidayDateInfoRequest: DataRequestFormProtocol, Encodable {
        var base: String { "https://apis.data.go.kr/B090041/openapi" }
        var path: String { "service/SpcdeInfoService/getRestDeInfo" }
        var method: HTTPMethod { .get }
        var validation: DataRequest.Validation? { nil }
        let apiKey: String
        let solYear: String
        let numOfRows: String = "100"
        let _type: String = "json"
        
        func asURLRequest() throws -> URLRequest {
            var request = try baseRequest
            let encodedKey: String = {
                if apiKey.contains("%") {
                    return apiKey
                }
                let reserved = CharacterSet(charactersIn: "+&=?/")
                let allowed = CharacterSet.urlQueryAllowed.subtracting(reserved)
                return apiKey.addingPercentEncoding(withAllowedCharacters: allowed) ?? apiKey
            }()
            
            var urlCompoents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            urlCompoents?.percentEncodedQueryItems = [
                URLQueryItem(name: "serviceKey", value: encodedKey),
                URLQueryItem(name: "solYear", value: solYear),
                URLQueryItem(name: "numOfRows", value: numOfRows),
                URLQueryItem(name: "_type", value: _type)
            ]
            request.url = urlCompoents?.url
            return request
        }
    }
    
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
    
    // MARK: 채널 정보 조회
    struct ChannelInfoRequest: DataRequestFormProtocol, Encodable {
        var path: String { "channels" }
        var method: HTTPMethod { .get }
        var validation: DataRequest.Validation? { nil }
        let key: String = API_KEY
        let part: String = "snippet"
        let forHandle: String = "QWER_Band_official"
        
        var parameters: Parameters? {
            return [
                "key" : key,
                "part" : part,
                "forHandle": forHandle
            ]
        }
        
        var encoding: ParameterEncoding { URLEncoding.queryString }
    }
}
