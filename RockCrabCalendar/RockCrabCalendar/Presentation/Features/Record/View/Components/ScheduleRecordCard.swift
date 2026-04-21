//
//  ScheduleRecordCard.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import RockCrabDomain
import SwiftUI

struct ScheduleRecordCard: View {
    let record: ScheduleRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(record.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(record.linkedSchedule.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(scheduleDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            if record.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                Text(record.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if record.photos.isEmpty == false {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle")
                    Text("\(record.photos.count)장")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var scheduleDateText: String {
        Self.scheduleDateFormatter.string(from: record.linkedSchedule.date)
    }

    private static let scheduleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter
    }()
}
