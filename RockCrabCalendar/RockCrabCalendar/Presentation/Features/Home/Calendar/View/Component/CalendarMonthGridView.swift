//
//  CalendarMonthGridView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 2025/01/14.
//

import SwiftUI

struct CalendarMonthGridView: View {
    let days: [Date]
    let numberOfWeeks: Int
    let availableWidth: CGFloat
    let isSelected: (Date) -> Bool
    let isInCurrentMonth: (Date) -> Bool
    let eventColors: (Date) -> [Color]
    let holidayName: (Date) -> String?
    let onSelectDate: (Date) -> Void
    let onChangeMonth: (Int) -> Void

    @Binding var dragOffset: CGFloat

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack {
            let interItemSpacing: CGFloat = 8
            let columns: CGFloat = 7
            let totalInteritem = interItemSpacing * (columns - 1)
            let usableWidth = max(0, availableWidth - totalInteritem)
            let cellWidth = floor(usableWidth / columns)
            let cellHeight = cellWidth * 1.05
            let totalGridHeight = (cellHeight * CGFloat(numberOfWeeks)) + (interItemSpacing * (CGFloat(numberOfWeeks) - 1))

            LazyVGrid(columns: gridColumns, spacing: interItemSpacing) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    CalendarDayCell(
                        date: date,
                        isSelected: isSelected(date),
                        isInCurrentMonth: isInCurrentMonth(date),
                        eventColors: eventColors(date),
                        holidayName: holidayName(date)
                    )
                    .frame(height: cellHeight)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.2)) {
                            onSelectDate(date)
                        }
                    }
                }
            }
            .offset(x: dragOffset)
            .frame(height: totalGridHeight)
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    dragOffset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let predicted = value.predictedEndTranslation.width
                    let final = dx + (predicted - dx) * 0.35
                    let threshold: CGFloat = 80
                    let slideDuration: TimeInterval = 0.2

                    if final <= -threshold {
                        withAnimation(.easeOut(duration: slideDuration)) {
                            dragOffset = -availableWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration) {
                            onChangeMonth(1)
                            dragOffset = 0
                        }
                    } else if final >= threshold {
                        withAnimation(.easeOut(duration: slideDuration)) {
                            dragOffset = availableWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration) {
                            onChangeMonth(-1)
                            dragOffset = 0
                        }
                    } else {
                        dragOffset = 0
                    }
                }
        )
    }
}
