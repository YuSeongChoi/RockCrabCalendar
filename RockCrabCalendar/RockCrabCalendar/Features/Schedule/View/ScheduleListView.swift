//
//  ScheduleListView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 11/27/25.
//

import SwiftUI

struct ScheduleListView: View {
    var calendarVM: CalendarViewModel
    var scheduleVM: QWERScheduleViewModel
    var userVM: UserScheduleViewModel
    @State private var holidayService: HolidayService = .shared
    
    @State private var editTarget: ScheduleEditView.Mode? = nil
    
    private let calendar = Calendar.current
    
    private let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = AppDateFormats.dayLabel
        return f
    }()
    
    var body: some View {
        Group {
            let qwerMonth = monthSchedulesForCurrentMonth()
            let userMonth = monthUserSchedulesForCurrentMonth()
            if qwerMonth.isEmpty && userMonth.isEmpty {
                EmptyStateView(
                    systemImage: "calendar.badge.exclamationmark",
                    title: "이번 달 일정이 없습니다"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                let groupedQ = Dictionary(grouping: qwerMonth) { calendar.startOfDay(for: $0.date) }
                let groupedU = Dictionary(grouping: userMonth) { calendar.startOfDay(for: $0.date) }
                let days = Set(groupedQ.keys).union(groupedU.keys).sorted()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(days, id: \.self) { day in
                            HStack(spacing: 6) {
                                Text(dayLabelFormatter.string(from: day))
                                    .pretendSemiBold(size: 16)
                                    .foregroundStyle(.secondary)
                                if let holiday = holidayService.name(on: day) {
                                    Text(holiday)
                                        .pretendSemiBold(size: 13)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if let qItems = groupedQ[day] {
                                scheduleListView(schedules: qItems)
                            }
                            if let uItems = groupedU[day] {
                                userScheduleListView(schedules: uItems)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .transition(.opacity)
            }
        }
        .navigationDestination(item: Binding(
            get: { editTarget },
            set: { editTarget = $0 }
        )) { mode in
            ScheduleEditView(
                mode: mode,
                defaultDate: scheduleVM.selectedDate,
                qwerVM: scheduleVM,
                userVM: userVM,
                defaultColor: {
                    if case .editUser(let item) = mode {
                        return Color(hex: item.colorHex)
                    } else {
                        return .purple
                    }
                }()
            )
        }
    }
    
    // MARK: 스케줄 리스트 뷰
    @ViewBuilder
    private func scheduleListView(schedules: [QWERScheduleItem]) -> some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .pretendSemiBold(size: 16)
                    
                    HStack(spacing: 8) {
                        Label(item.displayTime, systemImage: "clock")
                        Label(item.displayPlace, systemImage: "house.circle.fill")
                    }
                    .pretendReg(size: 13)
                    .foregroundColor(.gray)
                    
                    if !item.members.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: item.members.count == 1 ? "person.fill" : "person.3.fill")
                                .foregroundColor(.gray)
                            HStack(spacing: 8) {
                                ForEach(item.members, id: \.self) { member in
                                    Text(member.name)
                                        .pretendReg(size: 13)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule().fill(scheduleVM.memberColor(member))
                                        )
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    editTarget = .editQWER(item)
                }
            }
        }
            .frame(maxWidth: .infinity, alignment: .top)
            .transition(.opacity)
        
        ScrollView { content }
            .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    private func userScheduleListView(schedules: [UserScheduleItem]) -> some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .pretendSemiBold(size: 16)
                    }
                    
                    HStack(spacing: 8) {
                        Label(item.time.isEmpty ? "시간 미정" : item.time, systemImage: "clock")
                        Label(item.place.isEmpty ? "장소 미정" : item.place, systemImage: "house.circle.fill")
                    }
                    .pretendReg(size: 13)
                    .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Ensure we open the editor with the latest item from the view model (in case it was updated)
                    if let latest = userVM.schedules.first(where: { $0.id == item.id }) {
                        editTarget = .editUser(latest)
                    } else {
                        editTarget = .editUser(item)
                    }
                }
            }
        }
            .frame(maxWidth: .infinity, alignment: .top)
            .transition(.opacity)
        
        ScrollView { content }
            .scrollIndicators(.hidden)
    }
    
    private func monthSchedulesForCurrentMonth() -> [QWERScheduleItem] {
        let start = calendarVM.startOfMonth(for: calendarVM.currentMonth)
        let end = calendarVM.endOfMonth(for: calendarVM.currentMonth)
        return scheduleVM.schedules.filter { item in
            item.date >= start && item.date <= end && scheduleVM.activeCategories.contains(item.category)
        }.sorted { $0.date < $1.date }
    }
    
    private func monthUserSchedulesForCurrentMonth() -> [UserScheduleItem] {
        let start = calendarVM.startOfMonth(for: calendarVM.currentMonth)
        let end = calendarVM.endOfMonth(for: calendarVM.currentMonth)
        let interval = DateInterval(start: start, end: end)
        var result: [UserScheduleItem] = []
        for item in userVM.schedules {
            result.append(contentsOf: generateOccurrences(for: item, in: interval))
        }
        return result.sorted { $0.date < $1.date }
    }
    
    private func generateOccurrences(for item: UserScheduleItem, in range: DateInterval) -> [UserScheduleItem] {
        let cal = Calendar.current
        let rangeStart = cal.startOfDay(for: range.start)
        let rangeEnd = cal.startOfDay(for: range.end)
        
        // Non-repeating: include only if inside range
        if !item.isRepeat || item.repeatType == .none {
            let d = cal.startOfDay(for: item.date)
            guard d >= rangeStart && d <= rangeEnd else { return [] }
            return [UserScheduleItem(
                id: item.id,
                title: item.title,
                date: d,
                time: item.time,
                place: item.place,
                isRepeat: item.isRepeat,
                repeatType: item.repeatType,
                repeatEndDate: item.repeatEndDate
            )]
        }
        
        // Repeating: iterate occurrences
        var occurrences: [UserScheduleItem] = []
        var current = cal.startOfDay(for: item.date)
        let effectiveEnd = min(rangeEnd, cal.startOfDay(for: item.repeatEndDate ?? range.end))
        
        // Fast-forward to the first occurrence on/after rangeStart
        switch item.repeatType ?? .none {
        case .week:
            if current < rangeStart {
                if let days = cal.dateComponents([.day], from: current, to: rangeStart).day {
                    let remainder = days % 7
                    let advance = remainder == 0 ? 0 : (7 - remainder)
                    current = cal.date(byAdding: .day, value: days + advance, to: current) ?? current
                }
            }
        case .month, .year, .none:
            // We'll increment in the loop
            while current < rangeStart {
                guard let next = nextOccurrenceDate(from: current, type: item.repeatType ?? .none, calendar: cal) else { break }
                current = next
            }
        }
        
        while current <= effectiveEnd {
            if current >= rangeStart {
                occurrences.append(UserScheduleItem(
                    id: item.id,
                    title: item.title,
                    date: current,
                    time: item.time,
                    place: item.place,
                    isRepeat: item.isRepeat,
                    repeatType: item.repeatType,
                    repeatEndDate: item.repeatEndDate
                ))
            }
            guard let next = nextOccurrenceDate(from: current, type: item.repeatType ?? .none, calendar: cal) else { break }
            current = next
        }
        
        return occurrences
    }
    
    private func nextOccurrenceDate(from date: Date, type: UserScheduleItem.RepeatType, calendar cal: Calendar) -> Date? {
        switch type {
        case .none:
            return nil
        case .week:
            return cal.date(byAdding: .day, value: 7, to: date)
        case .month:
            return cal.date(byAdding: .month, value: 1, to: date)
        case .year:
            return cal.date(byAdding: .year, value: 1, to: date)
        }
    }
}
