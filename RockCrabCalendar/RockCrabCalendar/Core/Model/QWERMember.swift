//
//  QWERMember.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import SwiftUICore

enum QWERMember: String, CaseIterable, Codable {
    case Q, W, E, R
    
    var name: String {
        switch self {
        case .Q:
            return "쵸단"
        case .W:
            return "마젠타"
        case .E:
            return "히나"
        case .R:
            return "시연"
        }
    }
    
    var color: Color {
        switch self {
        case .Q:
            return Color.pastelChodan
        case .W:
            return Color.pastelMagenta
        case .E:
            return Color.pastelHina
        case .R:
            return Color.pastelMing
        }
    }
}
