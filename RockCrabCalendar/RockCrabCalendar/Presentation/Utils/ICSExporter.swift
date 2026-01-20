//
//  ICSExporter.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2026/01/15.
//

import Foundation
import RockCrabDomain

enum ICSExporter {
    static func makeCalendar(
        qwerSchedules: [QWERScheduleItem],
        userSchedules: [UserScheduleItem],
        calendarName: String = "RockCrabCalendar"
    ) -> String {
        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//RockCrabCalendar//Schedule Export//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "X-WR-CALNAME:\(escape(calendarName))"
        ]

        let stamp = dateTimeString(from: Date())

        for item in qwerSchedules {
            lines.append(contentsOf: eventLines(
                title: item.title,
                date: item.date,
                startTime: item.startTime,
                endTime: item.endTime,
                isAllDay: item.isAllDay,
                location: item.place,
                description: "QWER 일정",
                uidPrefix: "qwer",
                uid: item.id.uuidString,
                dtStamp: stamp
            ))
        }

        for item in userSchedules {
            lines.append(contentsOf: eventLines(
                title: item.title,
                date: item.date,
                startTime: item.startTime,
                endTime: item.endTime,
                isAllDay: item.isAllDay,
                location: item.place,
                description: "개인 일정",
                uidPrefix: "user",
                uid: item.id.uuidString,
                dtStamp: stamp
            ))
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    private static func eventLines(
        title: String,
        date: Date,
        startTime: Date?,
        endTime: Date?,
        isAllDay: Bool,
        location: String,
        description: String,
        uidPrefix: String,
        uid: String,
        dtStamp: String
    ) -> [String] {
        var lines: [String] = [
            "BEGIN:VEVENT",
            "UID:\(uidPrefix)-\(uid)@rockcrabcalendar",
            "DTSTAMP:\(dtStamp)",
            "SUMMARY:\(escape(title))"
        ]

        if !location.isEmpty {
            lines.append("LOCATION:\(escape(location))")
        }

        lines.append("DESCRIPTION:\(escape(description))")

        if isAllDay {
            let start = dateOnlyString(from: date)
            let end = dateOnlyString(from: Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date)
            lines.append("DTSTART;VALUE=DATE:\(start)")
            lines.append("DTEND;VALUE=DATE:\(end)")
        } else {
            let start = combine(date: date, time: startTime) ?? date
            let end = combine(date: date, time: endTime) ?? Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
            lines.append("DTSTART:\(dateTimeString(from: start))")
            lines.append("DTEND:\(dateTimeString(from: end))")
        }

        lines.append("END:VEVENT")
        return lines
    }

    private static func combine(date: Date, time: Date?) -> Date? {
        guard let time else { return nil }
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second ?? 0
        return calendar.date(from: dateComponents)
    }

    private static func dateTimeString(from date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    private static func dateOnlyString(from date: Date) -> String {
        dateOnlyFormatter.string(from: date)
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
