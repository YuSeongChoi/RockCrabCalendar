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

    var body: some View {
        GeometryReader { geometry in
            let rawSize = min(geometry.size.width, geometry.size.height)
            let cellSize = isSelected ? rawSize * 1.025 : rawSize
            
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.pastelBlue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.pastelBlue, lineWidth: 1.5)
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                        .shadow(color: Color.pastelBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                }

                if let date = date {
                    let day = Calendar.current.component(.day, from: date)
                    let weekday = Calendar.current.component(.weekday, from: date)

                    VStack(spacing: 10) {
                        Text("\(day)")
                            .font(.system(size: isSelected ? 18 : 16))
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundColor(isInCurrentMonth ? weekdayColor(weekday) : .gray.opacity(0.4))
                            .padding(.top, 4)
                        
                        if !eventColors.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(0..<eventColors.count, id: \.self) { i in
                                    ZStack {
                                        Circle()
                                            .fill(Color(white: 0.85))
                                            .frame(width: 7.5, height: 7.5)
                                        Circle()
                                            .fill(eventColors[i])
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                            .frame(height: 16)
                            .padding(.horizontal, 4)
                        } else {
                            Spacer().frame(height: 16)
                        }
                    }
                    .frame(width: geometry.size.width, height: cellSize * 1.18)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .frame(width: cellSize, height: cellSize * 1.08)
            .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white }))
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
