//
//  CalendarDayCell.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date?
    let isSelected: Bool
    let isInCurrentMonth: Bool
    let image: Image?
    let hasSchedule: Bool

    var body: some View {
        ZStack {
            if let date = date {
                Text("\(Calendar.current.component(.day, from: date))")
                    .foregroundColor(isInCurrentMonth ? .primary : .secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if isSelected {
                Circle()
                    .fill(Color.pastelBlue.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.pastelBlue, lineWidth: 1.5)
                    )
                    .shadow(color: Color.pastelBlue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .offset(y: 14)
            } else if hasSchedule {
                Circle()
                    .fill(Color.pastelMagenta)
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            }
        }
        .aspectRatio(1, contentMode: .fit)

    }
}

struct CalendarDayCell_Previews: PreviewProvider {
    static var previews: some View {
        CalendarDayCell(
            date: Date(),
            isSelected: true,
            isInCurrentMonth: true,
            image: Image(systemName: "star.fill"),
            hasSchedule: true
        )
        .previewLayout(.fixed(width: 50, height: 50))
    }
}
