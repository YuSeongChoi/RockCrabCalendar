//
//  QWERMember.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import Foundation
import RockCrabShared

public enum QWERMember: String, CaseIterable, Codable {
    case Q, W, E, R
    
    public var name: String {
        displayName
    }

    public var displayName: String {
        switch self {
        case .Q:
            return AppLocalization.string("쵸단", value: "쵸단")
        case .W:
            return AppLocalization.string("마젠타", value: "마젠타")
        case .E:
            return AppLocalization.string("히나", value: "히나")
        case .R:
            return AppLocalization.string("시연", value: "시연")
        }
    }

    public var fixedOrder: Int {
        switch self {
        case .Q:
            return 0
        case .W:
            return 1
        case .E:
            return 2
        case .R:
            return 3
        }
    }

    public static func fixedSorted(_ members: [QWERMember]) -> [QWERMember] {
        Array(Set(members)).sorted { $0.fixedOrder < $1.fixedOrder }
    }
}
