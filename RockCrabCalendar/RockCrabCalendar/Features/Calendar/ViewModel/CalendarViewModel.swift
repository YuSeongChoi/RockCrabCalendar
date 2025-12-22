//
//  CalendarViewModel.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 7/24/25.
//

import SwiftUI

@Observable
final class CalendarViewModel {
    var currentMonth: Date = Date() {
        didSet { generateDays() }
    }
    var days: [Date] = []
    var selectedDate: Date = Date()

    private let calendar = Calendar.current

    init() {
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
    
    private let storageKey = "holidayCacheData"
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd"
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
    
    /// 외부 API에서 받은 JSON 데이터를 넘기면 UserDefaults에 캐싱하고 메모리에 로드합니다.
    func updateWithJSONData(_ data: Data) {
        guard let decoded = decode(from: data) else { return }
        DispatchQueue.main.async { self.holidays = decoded }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = decode(from: data) {
            holidays = decoded
        }
    }
    
    private func loadBundledDefaults() {
        let defaults: [(String, String)] = []
        var map: [Date: Holiday] = [:]
        for (rawDate, name) in defaults {
            if let date = formatter.date(from: rawDate) {
                let key = calendar.startOfDay(for: date)
                map[key] = Holiday(date: key, name: name)
            }
        }
        holidays = map
    }
    
    private func decode(from data: Data) -> [Date: Holiday]? {
        struct HolidayDTO: Codable { let date: String; let name: String }
        guard let items = try? JSONDecoder().decode([HolidayDTO].self, from: data) else { return nil }
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
    func fetchHolidayOnce(baseYear: Int) async {
        let targetYears = Set([baseYear - 1, baseYear, baseYear + 1])
        let cachedYears = Set(UserDefaults.standard.array(forKey: "holidayCacheYears") as? [Int] ?? [])
        let cachedBaseYear = UserDefaults.standard.integer(forKey: "holidayCacheBaseYear")
        if cachedBaseYear == baseYear, !cachedYears.isEmpty {
            return
        }

        do {
            var holidayByDate: [String: String] = [:]
            let sortedYears = targetYears.sorted()
            for year in sortedYears {
                let response = try await HTTPRequestList.HolidayDateInfoRequest(
                    apiKey: HOLIDAY_API_KEY,
                    solYear: String(year)
                )
                .buildDataRequest()
                .serializingDecodable(HolidayResponse.self, automaticallyCancelling: true)
                .result
                .mapError { $0.underlyingError ?? $0 }
                .get()
                guard let items = response.response.body.items?.item else { continue }
                let dtos = items.filter { $0.isHoliday == "Y" }
                for dto in dtos {
                    let dateKey = formatHolidayDate(dto.locdate)
                    if holidayByDate[dateKey] == nil {
                        holidayByDate[dateKey] = dto.dateName
                    }
                }
            }

            let saveArray = holidayByDate
                .sorted { $0.key < $1.key }
                .map { ["date": $0.key, "name": $0.value] }
            let jsonData = try JSONSerialization.data(withJSONObject: saveArray)
            HolidayService.shared.updateWithJSONData(jsonData)

            UserDefaults.standard.set(Array(targetYears).sorted(), forKey: "holidayCacheYears")
            UserDefaults.standard.set(baseYear, forKey: "holidayCacheBaseYear")
            print("✅ 공휴일 데이터 최초 API 호출 및 저장 완료")
        } catch {
            print("❌ 공휴일 API 호출 실패:", error)
        }
    }

    private func formatHolidayDate(_ raw: Int) -> String {
        let rawString = String(raw)
        let input = DateFormatter()
        input.calendar = Calendar(identifier: .gregorian)
        input.locale = Locale(identifier: "ko_KR")
        input.timeZone = TimeZone(identifier: "Asia/Seoul")
        input.dateFormat = "yyyyMMdd"

        let output = DateFormatter()
        output.calendar = Calendar(identifier: .gregorian)
        output.locale = Locale(identifier: "ko_KR")
        output.timeZone = TimeZone(identifier: "Asia/Seoul")
        output.dateFormat = "yyyy-MM-dd"

        guard let date = input.date(from: rawString) else { return rawString }
        return output.string(from: date)
    }
}
