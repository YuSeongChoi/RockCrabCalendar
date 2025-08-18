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
    let eventColors: [Color]

    private let dotRowHeight: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let dayRectCorner: CGFloat = 8
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark

            ZStack(alignment: .top) {
                // Selection background – trimmed at the bottom so it won't overlap the dot row
                if isSelected {
                    RoundedRectangle(cornerRadius: dayRectCorner)
                        .fill(Color.pastelBlue.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: dayRectCorner)
                                .stroke(Color.pastelBlue, lineWidth: 1.5)
                        )
                        // cover the whole cell (day number + dots)
                        .frame(width: size.width, height: size.height)
                        // small inset so the stroke doesn’t touch grid bounds
                        .padding(3)
                        .shadow(color: Color.pastelBlue.opacity(0.2), radius: 3, x: 0, y: 1)
                }

                if let date = date {
                    let day = Calendar.current.component(.day, from: date)
                    let weekday = Calendar.current.component(.weekday, from: date)

                    VStack(spacing: 0) {
                        // Day number
                        Text("\(day)")
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isInCurrentMonth ? weekdayColor(weekday) : .gray.opacity(0.35))
                            .padding(.top, 6)

                        // Fill remaining vertical space, then place dots at the very bottom
                        Spacer(minLength: 0)

                        // Dot row (max ~6)
                        HStack(spacing: 3) {
                            if isInCurrentMonth {
                                ForEach(0..<min(eventColors.count, 6), id: \.self) { i in
                                    ZStack {
                                        Circle()
                                            .fill(Color(white: isDark ? 0.2 : 0.88))
                                            .frame(width: 8, height: 8)
                                        Circle()
                                            .fill(eventColors[i])
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .frame(height: dotRowHeight)
                        .padding(.bottom, 4)
                    }
                    .frame(width: size.width, height: size.height, alignment: .top)
                } else {
                    // Placeholder for empty cell (outside current grid)
                    Color.clear
                }
            }
            .frame(width: size.width, height: size.height)
            .background(
                Color(UIColor {
                    $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                })
            )
            .contentShape(Rectangle()) // make whole cell tappable
        }
    }

    private func weekdayColor(_ weekday: Int) -> Color {
        switch weekday {
        case 1: return .red       // Sunday
        case 7: return .blue      // Saturday
        default: return .primary  // Weekdays
        }
    }
}
