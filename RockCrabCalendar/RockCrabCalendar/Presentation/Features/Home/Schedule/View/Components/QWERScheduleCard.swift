//
//  QWERScheduleCard.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI
import RockCrabDomain

struct QWERScheduleCard: View {
    let item: QWERScheduleItem
    let memberColor: (QWERMember) -> Color
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .pretendSemiBold(size: 16)

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

            if !item.members.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: item.members.count == 1 ? "person.fill" : "person.3.fill")
                        .foregroundColor(.gray)
                    HStack(spacing: 8) {
                        ForEach(item.members, id: \.self) { member in
                            Text(member.name)
                                .pretendReg(size: 13)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(memberColor(member))
                                )
                                .foregroundColor(.black)
                        }
                    }
                }
            }
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
