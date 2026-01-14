//
//  HTTPRequestProtocol.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/1/25.
//

import Foundation
import Alamofire

protocol RequestFormProtocol: URLRequestConvertible {
    var base: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
}

extension RequestFormProtocol {
    var base: String { ServerConstant.baseURL }
    var baseRequest: URLRequest {
        get throws {
            let url = try base.asURL().appendingPathComponent(path)
            var request = URLRequest(url: url)
            request.method = method
            return request
        }
    }
}

protocol DataRequestFormProtocol: RequestFormProtocol, Sendable {
    var encoder: ParameterEncoder { get }
    var validation: DataRequest.Validation? { get }
    func buildDataRequest(_ interceptor: RequestInterceptor?) -> DataRequest
}

extension DataRequestFormProtocol {
    var encoder: ParameterEncoder {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd"
        let URLEncoder = URLEncodedFormEncoder(arrayEncoding: .noBrackets, dateEncoding: .formatted(formatter))
        return URLEncodedFormParameterEncoder(encoder: URLEncoder)
    }
    
    func buildDataRequest(_ interceptor: RequestInterceptor? = nil) -> DataRequest {
        let request = Session.HTTPclient.request(self, interceptor: interceptor).validate()
        if let validator = validation {
            return request.validate(validator)
        } else {
            return request
        }
    }
}

extension DataRequestFormProtocol where Self: Encodable {
    func asURLRequest() throws -> URLRequest {
        try encoder.encode(self, into: baseRequest)
    }
}

/// this Procotols network Error will be  not handled by the EventMonitor
public protocol URLRequestManagedErrorProtocol: URLRequestConvertible {}

public protocol PrefetchRequestProtocol: URLRequestConvertible {}
