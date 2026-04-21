//
//  ScheduleRecord.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation

public struct ScheduleRecord: Identifiable, Codable, Equatable {
    public enum LinkedScheduleKind: String, Codable, Equatable, CaseIterable {
        case qwer
        case user
    }

    public struct LinkedScheduleSnapshot: Codable, Equatable {
        public var kind: LinkedScheduleKind
        public var scheduleID: UUID
        public var title: String
        public var date: Date

        public init(
            kind: LinkedScheduleKind,
            scheduleID: UUID,
            title: String,
            date: Date
        ) {
            self.kind = kind
            self.scheduleID = scheduleID
            self.title = title
            self.date = date
        }
    }

    public struct Photo: Identifiable, Codable, Equatable {
        public var id: UUID
        public var fileName: String
        public var createdAt: Date

        public init(
            id: UUID = UUID(),
            fileName: String,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.fileName = fileName
            self.createdAt = createdAt
        }
    }

    public var id: UUID
    public var linkedSchedule: LinkedScheduleSnapshot
    public var emoji: String
    public var title: String
    public var body: String
    public var photos: [Photo]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        linkedSchedule: LinkedScheduleSnapshot,
        emoji: String,
        title: String,
        body: String,
        photos: [Photo] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.linkedSchedule = linkedSchedule
        self.emoji = emoji
        self.title = title
        self.body = body
        self.photos = Array(photos.prefix(Self.maxPhotoCount))
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static let maxPhotoCount = 5

    public var linkedScheduleKey: String {
        "\(linkedSchedule.kind.rawValue)-\(linkedSchedule.scheduleID.uuidString)"
    }
}
