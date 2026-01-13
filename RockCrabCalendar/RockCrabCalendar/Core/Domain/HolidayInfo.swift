//
//  HolidayInfo.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation

// Domain model for a holiday entry (used across layers).
struct HolidayInfo: Codable, Hashable {
    let date: String
    let name: String
}
