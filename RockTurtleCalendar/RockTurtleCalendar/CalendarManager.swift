//
//  CalendarManager.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import Foundation

class CalendarManager: ObservableObject {
    @Published var currentDate: Date
    private let calendar = Calendar.current
    
    init() {
        // 현재 날짜로 초기화
        self.currentDate = Date()
    }
    
    /// 현재 월의 첫번째 날짜 가져오기
    func startOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        return calendar.date(from: components) ?? Date()
    }
    
    /// 해당 월의 총 일 수
    func daysInMonth() -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate) else { return 0 }
        return range.count
    }
    
    /// 이전 월로 이동
    func goToPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    /// 다음 월로 이동
    func goToNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
}
