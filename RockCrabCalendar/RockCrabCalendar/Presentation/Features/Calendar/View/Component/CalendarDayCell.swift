//
//  CalendarDayCell.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/23/25.
//

import SwiftUI
import UIKit

struct CalendarDayCell: View {
    let date: Date?
    let isSelected: Bool
    let isInCurrentMonth: Bool
    let eventColors: [Color]
    let holidayName: String?

    private let dotSize: CGFloat = 6
    private let dotBackgroundSize: CGFloat = 8
    private var dotRowHeight: CGFloat { dotBackgroundSize + 6 } // auto-calculated from dot size + padding
    private let dayAreaHeight: CGFloat = 22
    private let holidayRowHeight: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let dayRectCorner: CGFloat = 8
            let isDark = UITraitCollection.current.userInterfaceStyle == .dark
            let isPad = UIDevice.current.userInterfaceIdiom == .pad

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: dayRectCorner)
                    .fill(Color.pastelHina.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: dayRectCorner)
                            .strokeBorder(Color.pastelHina, lineWidth: 1.5)
                    )
                    .frame(width: size.width, height: size.height)
                    .shadow(color: Color.pastelHina.opacity(0.2), radius: 3, x: 0, y: 1)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                if let date = date {
                    let day = Calendar.current.component(.day, from: date)
                    let weekday = Calendar.current.component(.weekday, from: date)
                    let isToday = Calendar.current.isDateInToday(date)

                    VStack(spacing: 0) {
                        CalendarDayNumberView(
                            day: day,
                            isToday: isToday,
                            isInCurrentMonth: isInCurrentMonth,
                            weekday: weekday,
                            dayAreaHeight: dayAreaHeight
                        )
                        let holidayText = (holidayName != nil && isInCurrentMonth) ? holidayName! : " "
                        Text(holidayText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.top, 2)
                            .frame(height: holidayRowHeight, alignment: .top)
                            .opacity((holidayName != nil && isInCurrentMonth) ? 1 : 0)

                        if isPad {
                            // iPad 등 큰 셀: 날짜 바로 아래에 점들 표시 (최대 5개)
                            EventDotRow(
                                colors: eventColors,
                                isDark: isDark,
                                isInCurrentMonth: isInCurrentMonth,
                                dotBackgroundSize: dotBackgroundSize,
                                dotSize: dotSize
                            )
                            .animation(nil, value: eventColors)
                            .frame(height: dotRowHeight)
                            .padding(.top, 4)

                            Spacer(minLength: 0)
                        } else {
                            // iPhone 등 작은 셀: 기존처럼 하단 배치 유지 (최대 5개)
                            Spacer(minLength: 0)

                            EventDotRow(
                                colors: eventColors,
                                isDark: isDark,
                                isInCurrentMonth: isInCurrentMonth,
                                dotBackgroundSize: dotBackgroundSize,
                                dotSize: dotSize
                            )
                            .animation(nil, value: eventColors)
                            .frame(height: dotRowHeight)
                            .padding(.bottom, 4)
                        }
                    }
                    .frame(width: size.width, height: size.height, alignment: .top)
                } else {
                    Color.clear
                }
            }
            .frame(width: size.width, height: size.height)
            .background(
                Color.appBackground
            )
            .contentShape(Rectangle())
        }
    }

    private func weekdayColor(_ weekday: Int) -> Color {
        if holidayName != nil { return .red }
        switch weekday {
        case 1: return .red       // Sunday
        case 7: return .blue      // Saturday
        default: return .primary  // Weekdays
        }
    }
}

private struct CalendarDayNumberView: View {
    let day: Int
    let isToday: Bool
    let isInCurrentMonth: Bool
    let weekday: Int
    let dayAreaHeight: CGFloat

    var body: some View {
        ZStack {
            if isToday {
                let base = Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark ? UIColor(.white) : UIColor(.gray)
                })
                Circle()
                    .fill(base.opacity(0.28))
                    .overlay(
                        Circle().stroke(base.opacity(0.6), lineWidth: 1)
                    )
                    .frame(width: 24, height: 24)
                    .padding(.top, 1)
            }
            Text("\(day)")
                .pretendSemiBold(size: 15)
                .monospacedDigit()
                .frame(height: dayAreaHeight, alignment: .top)
                .foregroundColor(isInCurrentMonth ? weekdayColor(weekday) : .gray.opacity(0.35))
                .padding(.top, 3)
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

private struct EventDotRow: View {
    let colors: [Color]
    let isDark: Bool
    let isInCurrentMonth: Bool
    let dotBackgroundSize: CGFloat
    let dotSize: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(colors.count, 5), id: \.self) { i in
                ZStack {
                    Circle()
                        .fill(Color(white: isDark ? 0.2 : 0.88))
                        .opacity(isInCurrentMonth ? 1 : 0.55)
                        .frame(width: dotBackgroundSize, height: dotBackgroundSize)
                    Circle()
                        .fill(colors[i])
                        .opacity(isInCurrentMonth ? 1 : 0.5)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
    }
}
