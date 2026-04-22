//
//  ScheduleRecordCard.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation
import RockCrabDomain
import RockCrabShared
import SwiftUI
import UIKit

struct ScheduleRecordCard: View {
    let record: ScheduleRecord
    private let photoStore = RecordPhotoStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                leadingMedia

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.linkedSchedule.title)
                        .font(.headline)
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

    @ViewBuilder
    private var leadingMedia: some View {
        if let image = firstPhotoImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Self.mediaSize, height: Self.mediaSize)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .clipped()
        } else {
            Text(record.emoji)
                .font(.system(size: 32))
                .frame(width: Self.mediaSize, height: Self.mediaSize)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var firstPhotoImage: UIImage? {
        guard let firstPhoto = record.photos.first else { return nil }

        let cacheKey = firstPhoto.fileName as NSString
        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let image = photoStore.image(fileName: firstPhoto.fileName) else {
            return nil
        }

        Self.imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    private var scheduleDateText: String {
        Self.scheduleDateFormatter.string(from: record.linkedSchedule.date)
    }

    private static let scheduleDateFormatter: DateFormatter = {
        let formatter = AppDateFormatterFactory.recordDetailDateFormatter()
        return formatter
    }()

    private static let mediaSize: CGFloat = 56
    private static let imageCache = NSCache<NSString, UIImage>()
}
