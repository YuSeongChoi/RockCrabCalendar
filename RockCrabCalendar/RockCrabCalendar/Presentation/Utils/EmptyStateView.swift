//
//  EmptyStateView.swift
//  RockCrabCalendar
//
//  Lightweight empty-state component for list/calendar views.
//

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String?

    init(systemImage: String, title: String, subtitle: String? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text(LocalizedStringKey(title))
                .font(.callout)
                .foregroundStyle(.secondary)
            if let subtitle, !subtitle.isEmpty {
                Text(LocalizedStringKey(subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
