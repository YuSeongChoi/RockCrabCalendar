//
//  QWERMember.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/30/25.
//

import Foundation

public enum QWERMember: String, CaseIterable, Codable {
    case Q, W, E, R
    
    public var name: String {
        displayName
    }

    public var displayName: String {
        switch self {
        case .Q:
            return NSLocalizedString("쵸단", bundle: .main, value: "쵸단", comment: "")
        case .W:
            return NSLocalizedString("마젠타", bundle: .main, value: "마젠타", comment: "")
        case .E:
            return NSLocalizedString("히나", bundle: .main, value: "히나", comment: "")
        case .R:
            return NSLocalizedString("시연", bundle: .main, value: "시연", comment: "")
        }
    }
}
