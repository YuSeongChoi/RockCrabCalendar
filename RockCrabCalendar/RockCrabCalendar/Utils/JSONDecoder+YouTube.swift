//
//  JSONDecoder+YouTube.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 9/9/25.
//

import Foundation

public enum YouTubeDateParser {
    // 유튜브는 마이크로초가 붙는 ISO8601를 사용
    public static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    public static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// 문자열 ISO8601(Z/마이크로초 포함 가능) → Date로 변환
    /// - Parameter string: 예) "2025-06-08T03:00:12Z" 또는 "2025-06-08T03:00:12.123Z"
    /// - Returns: 파싱 성공 시 Date, 실패 시 nil
    @inlinable
    public static func parse(_ string: String?) -> Date? {
        guard let s = string, !s.isEmpty else { return nil }
        // 마이크로초 포함 포맷 우선 시도 → 일반 ISO8601 순으로 시도
        if let d = iso8601WithFractional.date(from: s) { return d }
        if let d = iso8601.date(from: s) { return d }
        return nil
    }
}

public extension JSONDecoder {
    /// 유튜브 응답 공통 디코더(추가 규칙이 필요해지면 여기서 확장)
    static var youtube: JSONDecoder {
        let decoder = JSONDecoder()
        // 현재 DTO에서는 Date 필드가 없지만, 나중에 필요하면 여기서 custom 지정
        // decoder.dateDecodingStrategy = .custom { dec in ... }
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }
}
