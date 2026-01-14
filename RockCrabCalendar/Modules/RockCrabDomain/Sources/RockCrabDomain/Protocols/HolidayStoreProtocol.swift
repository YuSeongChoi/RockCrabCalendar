//
//  HolidayStoreProtocol.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import Foundation
import RockCrabShared

public protocol HolidayStoreProtocol {
    func name(on date: Date) -> String?
    func updateWithItems(_ items: [HolidayInfo])
}
