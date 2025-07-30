//
//  QWERMember.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import SwiftUICore

enum QWERMember: String, CaseIterable, Codable {
    case chodan, magenta, hina, siyo
    
    var name: String {
        switch self {
        case .chodan:
            return "쵸단"
        case .magenta:
            return "마젠타"
        case .hina:
            return "히나"
        case .siyo:
            return "시연"
        }
    }
    
    var color: Color {
        switch self {
        case .chodan:
            return Color.pastelChodan
        case .magenta:
            return Color.pastelMagenta
        case .hina:
            return Color.pastelHina
        case .siyo:
            return Color.pastelMing
        }
    }
}
