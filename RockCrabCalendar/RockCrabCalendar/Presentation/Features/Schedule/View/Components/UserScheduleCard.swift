//
//  UserScheduleCard.swift
//  RockCrabCalendar
//
//  Created by Codex on 2025/01/14.
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
                Label(item.displayPlace, systemImage: "house.circle.fill")
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
