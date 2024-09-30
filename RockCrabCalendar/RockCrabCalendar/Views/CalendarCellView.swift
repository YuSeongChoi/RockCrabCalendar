//
//  CalendarCellView.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/27/24.
//

import SwiftUI

struct CalendarCellView: View {
    private var day: Int
    private var clicked: Bool
    private var isToday: Bool
    private var isCurrentMonthDay: Bool
    private var textColor: Color {
        if clicked || isToday {
            return .white
        } else if isCurrentMonthDay {
            return .black
        } else {
            return .gray
        }
    }
    private var backgroundColor: Color {
        if clicked {
            return .black
        } else if isToday {
            return R.color.darkindigo.swiftColor
        } else {
            return .white
        }
    }
    
    init(
        day: Int,
        clicked: Bool = false,
        isToday: Bool = false,
        isCurrentMonthDay: Bool = true
    ) {
        self.day = day
        self.clicked = clicked
        self.isToday = isToday
        self.isCurrentMonthDay = isCurrentMonthDay
    }
    
    var body: some View {
        VStack {
            Text(String(day))
                .pretendMid(size: 13)
                .foregroundStyle(textColor)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 24, height: 24)
                )
            Spacer()
            // TODO: todo-list가 있을때 표시할 곳
        }
        .frame(height: 80)
    }
}

#Preview {
    CalendarCellView(day: 16)
}
