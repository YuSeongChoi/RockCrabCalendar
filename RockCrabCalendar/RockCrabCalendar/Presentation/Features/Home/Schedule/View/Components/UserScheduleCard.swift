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

    var body: some View {
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardBackground)
        )
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
