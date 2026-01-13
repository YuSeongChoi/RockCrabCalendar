//
//  HolidayInfo.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Domain model for a holiday entry (used across layers).
public struct HolidayInfo: Codable, Hashable {
    public let date: String
    public let name: String

    public init(date: String, name: String) {
        self.date = date
        self.name = name
    }
}
