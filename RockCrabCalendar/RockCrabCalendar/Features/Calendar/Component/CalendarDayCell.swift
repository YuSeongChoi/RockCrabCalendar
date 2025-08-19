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

    private let dotSize: CGFloat = 6
    private let dotBackgroundSize: CGFloat = 8
    private var dotRowHeight: CGFloat { dotBackgroundSize + 6 } // auto-calculated from dot size + padding
    private let dayAreaHeight: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let dayRectCorner: CGFloat = 8
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: dayRectCorner)
                    .fill(Color.pastelBlue.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: dayRectCorner)
                            .strokeBorder(Color.pastelBlue, lineWidth: 1.5)
                    )
                    .frame(width: size.width, height: size.height)
                    .shadow(color: Color.pastelBlue.opacity(0.2), radius: 3, x: 0, y: 1)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                if let date = date {
                    let day = Calendar.current.component(.day, from: date)
                    let weekday = Calendar.current.component(.weekday, from: date)

                    VStack(spacing: 0) {
                        Text("\(day)")
                            .pretendSemiBold(size: 15)
                            .monospacedDigit()
                            .frame(height: dayAreaHeight, alignment: .top)
                            .foregroundColor(isInCurrentMonth ? weekdayColor(weekday) : .gray.opacity(0.35))
                            .padding(.top, 6)

                        Spacer()

                        HStack(spacing: 3) {
                            ForEach(0..<min(eventColors.count, 6), id: \.self) { i in
                                ZStack {
                                    Circle()
                                        .fill(Color(white: isDark ? 0.2 : 0.88))
                                        .opacity(isInCurrentMonth ? 1 : 0.55)
                                        .frame(width: dotBackgroundSize, height: dotBackgroundSize)
                                    Circle()
                                        .fill(eventColors[i])
                                        .opacity(isInCurrentMonth ? 1 : 0.5)
                                        .frame(width: dotSize, height: dotSize)
                                }
                            }
                        }
                        .frame(height: dotRowHeight)
                        .padding(.bottom, 4)
                    }
                    .frame(width: size.width, height: size.height, alignment: .top)
                } else {
                    Color.clear
                }
            }
            .frame(width: size.width, height: size.height)
            .background(
                Color(UIColor {
                    $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
                })
            )
            .contentShape(Rectangle())
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
