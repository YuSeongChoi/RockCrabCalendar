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
                        ZStack {
                            if isToday {
                                // 라이트/다크 모두 가시성 좋은 오늘 배경 색
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
                        if let holiday = holidayName, isInCurrentMonth {
                            Text(holiday)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.top, 2)
                        }

                        if isPad {
                            // iPad 등 큰 셀: 날짜 바로 아래에 점들 표시 (최대 5개)
                            HStack(spacing: 3) {
                                ForEach(0..<min(eventColors.count, 5), id: \.self) { i in
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
                            .padding(.top, 4)

                            Spacer(minLength: 0)
                        } else {
                            // iPhone 등 작은 셀: 기존처럼 하단 배치 유지 (최대 5개)
                            Spacer(minLength: 0)

                            HStack(spacing: 3) {
                                ForEach(0..<min(eventColors.count, 5), id: \.self) { i in
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
        if holidayName != nil { return .red }
        switch weekday {
        case 1: return .red       // Sunday
        case 7: return .blue      // Saturday
        default: return .primary  // Weekdays
        }
    }
}
