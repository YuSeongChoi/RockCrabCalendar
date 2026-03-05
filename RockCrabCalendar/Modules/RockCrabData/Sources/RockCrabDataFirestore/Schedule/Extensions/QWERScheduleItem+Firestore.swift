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
        let resolvedIsAllDay = (startTime == nil && endTime == nil) ? isAllDay : false
        var dict: [String: Any] = [
            "title": title,
            "date": Timestamp(date: date),
            "place": place,
            "members": members.map { $0.rawValue },
            "category": category.rawValue,
            "isAllDay": resolvedIsAllDay
        ]

        if let startTime = startTime {
            dict["startTime"] = Timestamp(date: startTime)
        }
        if let endTime = endTime {
            dict["endTime"] = Timestamp(date: endTime)
        }

        dict["time"] = time // keep until post-launch cleanup
        return dict
    }
}
