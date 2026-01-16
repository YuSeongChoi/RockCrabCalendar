//
//  QWERStyleMapper.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/01/15.
//

import SwiftUI
import RockCrabDomain

enum QWERStyleMapper {
    static func memberColor(_ member: QWERMember) -> Color {
        switch member {
        case .Q: return .pastelChodan
        case .W: return .pastelMagenta
        case .E: return .pastelHina
        case .R: return .pastelMing
        }
    }
}
