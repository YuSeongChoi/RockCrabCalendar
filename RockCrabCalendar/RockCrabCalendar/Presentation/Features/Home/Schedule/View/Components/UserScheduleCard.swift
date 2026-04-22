//
//  UserScheduleCard.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct UserScheduleCard: View {
    let item: UserScheduleItem
    let onTap: () -> Void
    let onRecord: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tappableContent
            recordButton
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal, 10)
    }

    private var tappableContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(item.title)
                    .pretendSemiBold(size: 16)
            }

            HStack(spacing: 8) {
                Label(item.displayTime, systemImage: "clock")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                Label(item.displayPlace, systemImage: "house.circle.fill")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .layoutPriority(1)
            }
            .pretendReg(size: 13)
            .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var recordButton: some View {
        Button(action: onRecord) {
            Label("기록", systemImage: "square.and.pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}
