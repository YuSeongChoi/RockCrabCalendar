//
//  UserScheduleMigrationStoreProtocol.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
//

import Foundation

public protocol UserScheduleMigrationStoreProtocol {
    func isLegacyTimeMigrationDone() -> Bool
    func markLegacyTimeMigrationDone()
}
