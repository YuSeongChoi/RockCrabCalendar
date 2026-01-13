//
//  CalendarViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import SwiftUI
import RockCrabShared

@Observable
final class CalendarViewModel {
    var currentMonth: Date = Date() {
        didSet { generateDays() }
    }
    var days: [Date] = []
    var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let holidayUseCase: HolidayUseCase

    // Inject use-case for holiday sync.
    init(holidayUseCase: HolidayUseCase = HolidayUseCase(repository: HolidayRepository())) {
        self.holidayUseCase = holidayUseCase
        generateDays()
    }

    func generateDays() {
        days = CalendarGenerator.generateDaysInMonth(for: currentMonth, calendar: calendar)
    }

    func changeMonth(by offset: Int) {
        if let next = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = next
        }
    }

    func select(date: Date) {
        selectedDate = date
    }

    // 유틸 메서드
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    func startOfMonth(for date: Date) -> Date {
        return date.startOfMonth
    }

    func endOfMonth(for date: Date) -> Date {
        return date.endOfMonth
    }
    
    var numberOfWeeks: Int {
        return (days.count + 6) / 7
    }

    func cellHeight(for totalHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 240
        let adjustedHeight = max(totalHeight, minHeight)
        return adjustedHeight / CGFloat(numberOfWeeks)
    }
}

// MARK: - Holiday support
struct Holiday: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    let date: Date
    let name: String
}

@Observable
final class HolidayService {
    static let shared = HolidayService()
    private(set) var holidays: [Date: Holiday] = [:]
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()
    
    private let storageKey = AppStorageKeys.holidayCacheData
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = AppDateFormats.serverDay
        return f
    }()
    
    init() {
        loadFromCache()
        if holidays.isEmpty {
            loadBundledDefaults()
        }
    }
    
    func name(on date: Date) -> String? {
        let key = calendar.startOfDay(for: date)
        return holidays[key]?.name
    }
    
    /// 외부 API에서 받은 도메인 모델을 넘기면 UserDefaults에 캐싱하고 메모리에 로드합니다.
    func updateWithItems(_ items: [HolidayInfo]) {
        guard let decoded = decode(from: items) else { return }
        DispatchQueue.main.async { self.holidays = decoded }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = decode(from: data) {
            holidays = decoded
        }
    }
    
    private func loadBundledDefaults() {
        let defaults: [HolidayInfo] = []
        var map: [Date: Holiday] = [:]
        for item in defaults {
            if let date = formatter.date(from: item.date) {
                let key = calendar.startOfDay(for: date)
                map[key] = Holiday(date: key, name: item.name)
            } 
        }
        holidays = map
    }
    
    private func decode(from data: Data) -> [Date: Holiday]? {
        guard let items = try? JSONDecoder().decode([HolidayInfo].self, from: data) else { return nil }
        return decode(from: items)
    }

    private func decode(from items: [HolidayInfo]) -> [Date: Holiday]? {
        var map: [Date: Holiday] = [:]
        for item in items {
            if let date = formatter.date(from: item.date) {
                let key = calendar.startOfDay(for: date)
                map[key] = Holiday(date: key, name: item.name)
            }
        }
        return map
    }
}

extension CalendarViewModel {
    // Fetch holiday data once using the use-case boundary.
    func fetchHolidayOnce(baseYear: Int) async {
        do {
            if let items = try await holidayUseCase.fetchIfNeeded(baseYear: baseYear) {
                HolidayService.shared.updateWithItems(items)
                print("✅ 공휴일 데이터 최초 API 호출 및 저장 완료")
            }
        } catch {
            print("❌ 공휴일 API 호출 실패:", error)
        }
    }
}
