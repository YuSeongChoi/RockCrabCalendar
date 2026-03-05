//
//  QWERScheduleItem+Firestore.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/09.
//

import Foundation
import FirebaseFirestore
import RockCrabDomain

// Firestore mapping for QWERScheduleItem.
extension QWERScheduleItem {
    var asDictionary: [String: Any] {
        let resolvedIsAllDay = timeStatus == .allDay
        let legacyTimeString: String = {
            guard let startTime else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = .autoupdatingCurrent
            return formatter.string(from: startTime)
        }()
        var dict: [String: Any] = [
            "title": title,
            "date": Timestamp(date: date),
            "place": place,
            "members": members.map { $0.rawValue },
            "category": category.rawValue,
            "isAllDay": resolvedIsAllDay,
            "timeStatus": timeStatus.rawValue,
            // Backward compatibility for older app versions still reading legacy field.
            "time": legacyTimeString
        ]

        if let startTime = startTime {
            dict["startTime"] = Timestamp(date: startTime)
        }
        if let endTime = endTime {
            dict["endTime"] = Timestamp(date: endTime)
        }

        return dict
    }
}
