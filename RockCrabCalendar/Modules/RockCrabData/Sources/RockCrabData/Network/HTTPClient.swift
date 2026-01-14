//
//  HTTPClient.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/1/25.
//

import Foundation
import os
import Alamofire
import RockCrabShared

extension Session {
    static var newInstance: Session {
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 30
        let eventMonitors: [EventMonitor] = [DataMonitor(), AlertEventMonitor()]
        let session = Session(configuration: config, cachedResponseHandler: ResponseCacher.cache, eventMonitors: eventMonitors)
        return session
    }
    
    static let HTTPclient: Session = .newInstance
}

struct AlertEventMonitor: EventMonitor {
    var queue: DispatchQueue { .global(qos: .userInitiated) }
    
    func requestDidFinish(_ request: Request) {
        guard let error = request.error,
              !error.isExplicitlyCancelledError else {
            return
        }
        
        if let dataRequest = request as? DataRequest,
           dataRequest.convertible is URLRequestManagedErrorProtocol {
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let notification = Notification(name: AlertNotificationName.networkError, object: error.underlyingError ?? error)
                NotificationCenter.default.post(notification)
            }
        }
    }
    
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        guard let error = response.error,
              case .responseSerializationFailed = error else {
            return
        }
        
        if request.convertible is URLRequestManagedErrorProtocol {
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let notification = Notification(name: AlertNotificationName.networkError, object: error.underlyingError ?? error)
                NotificationCenter.default.post(notification)
            }
        }
    }
}

struct DataMonitor: EventMonitor {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier.unsafelyUnwrapped,
        category: "Alamofire"
    )
    let queue: DispatchQueue = .global(qos: .background)
    
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let result: Result<Data?,AFError>
        if let error = response.error {
            result = .failure(error)
        } else {
            result = .success(response.data)
        }
        
        let dataResponse = DataResponse(request: response.request, response: response.response, data: response.data, metrics: response.metrics, serializationDuration: response.serializationDuration, result: result)
        dataRequestDidParseResponse(request, didParseResponse: dataResponse)
    }
    
    func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        dataRequestDidParseResponse(request, didParseResponse: response)
    }
    
    private func dataRequestDidParseResponse(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
        var debugDescription = response.debugDescription
        debugDescription = debugDescription.replacingOccurrences(of: "\n", with: "\n│ ")
            .replacingOccurrences(of: "(\\[Body]:)\\s*\n│", with: "[Body]:\n ", options: [.regularExpression])
        
        switch request {
        case let (uploadRequest as UploadRequest):
            switch uploadRequest.uploadable {
            case .none:
                break
            case .some(.data(_)):
                break
            case .some(.file(_, shouldRemove: _)):
                break
            case .some(.stream(_)):
                break
            }
        default:
            if let requestData = response.request?.httpBody,
               !requestData.isEmpty,
               debugDescription.contains("[Body]: \(requestData)"),
               let contentType = response.request?.value(forHTTPHeaderField: "Content-Type"),
               contentType.lowercased().contains("charset=utf-8") {
                let requestBody = String(decoding: requestData, as: UTF8.self)
                debugDescription = debugDescription.replacingOccurrences(of: "[Body]: \(requestData)", with: "[Body]:\n\t\t\(requestBody)")
            }
        }
        logger.log(
            level: .debug,
"""

┌───────────────────────────────────────────────
│ \(debugDescription)
└───────────────────────────────────────────────
"""
        )
    }
}
