//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    var calendarVM: CalendarViewModel
    var scheduleVM: QWERScheduleViewModel
    var userVM: UserScheduleViewModel
    @State private var holidayService: HolidayService = .shared
    
    @State private var dragOffset: CGFloat = 0
    @State private var editTarget: ScheduleEditView.Mode? = nil
    
    private let lastSyncFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = AppDateFormats.lastSync
        return f
    }()
    private var lastSyncText: String {
        if let dt = scheduleVM.lastFetchedAt {
            return "최근 동기화: \(lastSyncFormatter.string(from: dt))"
        } else {
            return "최근 동기화 기록 없음"
        }
    }
    
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    dateHeaderView
                    dateGridView(availableWidth: geometry.size.width)
                    
                    // 최근 동기화 캡션
                    Text(lastSyncText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 4)
                    Divider()
                }
                
                ZStack {
                    let selectedQWER = scheduleVM.schedules(on: scheduleVM.selectedDate)
                    let selectedUser = userSchedules(on: scheduleVM.selectedDate)
                    if !selectedQWER.isEmpty || !selectedUser.isEmpty {
                        ScrollView {
                            VStack(spacing: 16) {
                                if !selectedQWER.isEmpty {
                                    scheduleListView(schedules: selectedQWER, embedInScrollView: false)
                                        .padding(.top, 12)
                                }
                                if !selectedUser.isEmpty {
                                    userScheduleListView(schedules: selectedUser, embedInScrollView: false)
                                        .padding(.top, selectedQWER.isEmpty ? 12 : 0)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        Spacer()
                        EmptyStateView(
                            systemImage: "calendar.badge.exclamationmark",
                            title: "일정이 없습니다"
                        )
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
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
    
    // MARK: 요일 헤더 뷰
    @ViewBuilder
    private var dateHeaderView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                let color: Color = {
                    if index == 0 { return Color.red.opacity(0.85) }
                    if index == 6 { return Color.blue.opacity(0.85) }
                    return .secondary
                }()
                Text(day)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(.bottom, 15)
    }
    
    // MARK: 요일 그리드 뷰
    private func dateGridView(availableWidth: CGFloat) -> some View {
        VStack {
            let numberOfWeeks = CGFloat(calendarVM.numberOfWeeks)
            
            // 셀 사이 간격 (LazyVGrid spacing과 동일해야 함)
            let interItemSpacing: CGFloat = 8
            // 열 개수 (요일: 7일)
            let columns: CGFloat = 7
            
            // 전체 가로 간격의 합 = 간격 * (열 - 1)
            let totalInteritem = interItemSpacing * (columns - 1)
            // 사용할 수 있는 실제 셀 영역 = 전체 너비 - 간격 합
            let usableWidth = max(0, availableWidth - totalInteritem)
            // 셀 하나의 가로 폭 = usableWidth ÷ 열 개수 (내림하여 픽셀 깨짐 방지)
            let cellWidth = floor(usableWidth / columns)
            
            // 셀 높이 = 셀 폭보다 약간 크게 (이벤트 점 표시 공간 확보)
            let cellHeight = cellWidth * 1.05
            
            // 전체 그리드 높이 = (셀 높이 × 주 수) + (간격 × (주 수 - 1))
            let totalGridHeight = (cellHeight * numberOfWeeks) + (interItemSpacing * (numberOfWeeks - 1))
            
            LazyVGrid(columns: gridColumns, spacing: interItemSpacing) {
                ForEach(Array(calendarVM.days.enumerated()), id: \.offset) { _, date in
                    CalendarDayCell(
                        date: date,
                        isSelected: calendarVM.isSelected(date),
                        isInCurrentMonth: calendarVM.isInCurrentMonth(date),
                        eventColors: combinedEventColors(for: date),
                        holidayName: holidayService.name(on: date)
                    )
                    .frame(height: cellHeight)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.2)) {
                            calendarVM.select(date: date)
                            scheduleVM.selectedDate = date
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
                    // 수평 스와이프 우선 (수직 드래그는 무시)
                    guard abs(dx) > abs(dy) else { return }
                    dragOffset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let predicted = value.predictedEndTranslation.width
                    let final = dx + (predicted - dx) * 0.35
                    let threshold: CGFloat = 80
                    
                    if final <= -threshold {
                        // 다음 달로 이동 (왼쪽으로 슬라이드 아웃/인)
                        withAnimation(.linear(duration: 0.20)) {
                            dragOffset = -availableWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            calendarVM.changeMonth(by: 1)
                            dragOffset = availableWidth
                            withAnimation(.linear(duration: 0.20)) {
                                dragOffset = 0
                            }
                        }
                    } else if final >= threshold {
                        // 이전 달로 이동 (오른쪽으로 슬라이드 아웃/인)
                        withAnimation(.linear(duration: 0.20)) {
                            dragOffset = availableWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            calendarVM.changeMonth(by: -1)
                            dragOffset = -availableWidth
                            withAnimation(.linear(duration: 0.20)) {
                                dragOffset = 0
                            }
                        }
                    } else {
                        // 임계값 미만: 원위치로 부드럽게 복귀 (선형)
                        withAnimation(.linear(duration: 0.18)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
    
    private func combinedEventColors(for date: Date) -> [Color] {
        var colors = scheduleVM.eventColors(for: date)
        let items = userVM.schedules.filter { occursOnDate($0, on: date) }
        colors.append(contentsOf: items.map { Color(hex: $0.colorHex) })
        return colors
    }
    
    private func userSchedules(on date: Date) -> [UserScheduleItem] {
        userVM.schedules.compactMap { item in
            occursOnDate(item, on: date) ? UserScheduleItem(
                id: item.id,
                title: item.title,
                date: Calendar.current.startOfDay(for: date),
                time: item.time,
                isAllDay: item.isAllDay,
                startTime: item.startTime,
                endTime: item.endTime,
                place: item.place,
                isRepeat: item.isRepeat,
                repeatType: item.repeatType,
                repeatEndDate: item.repeatEndDate,
                colorHex: item.colorHex
            ) : nil
        }
    }
    
    private func occursOnDate(_ item: UserScheduleItem, on target: Date) -> Bool {
        let cal = Calendar.current
        let start = cal.startOfDay(for: item.date)
        let t = cal.startOfDay(for: target)
        
        // Non-repeating
        if !item.isRepeat || item.repeatType == Optional.none {
            return cal.isDate(start, inSameDayAs: t)
        }
        
        // Respect end date if provided
        if let end = item.repeatEndDate, t > cal.startOfDay(for: end) { return false }
        if t < start { return false }
        
        switch item.repeatType ?? .none {
        case .none:
            return cal.isDate(start, inSameDayAs: t)
        case .week:
            let days = cal.dateComponents([.day], from: start, to: t).day ?? 0
            return days >= 0 && days % 7 == 0
        case .month:
            let comps = cal.dateComponents([.year, .month, .day], from: start)
            let tComps = cal.dateComponents([.year, .month, .day], from: t)
            guard let diffMonths = cal.dateComponents([.month], from: start, to: t).month, diffMonths >= 0 else { return false }
            // Same day-of-month is considered a match
            return comps.day == tComps.day
        case .year:
            let comps = cal.dateComponents([.month, .day], from: start)
            let tComps = cal.dateComponents([.month, .day], from: t)
            guard let diffYears = cal.dateComponents([.year], from: start, to: t).year, diffYears >= 0 else { return false }
            return comps.month == tComps.month && comps.day == tComps.day
        }
    }
    
    // MARK: 스케줄 리스트 뷰
    @ViewBuilder
    private func scheduleListView(schedules: [QWERScheduleItem], embedInScrollView: Bool = true) -> some View {
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
        
        if embedInScrollView {
            ScrollView { content }
                .scrollIndicators(.hidden)
        } else {
            content
        }
    }
    
    @ViewBuilder
    private func userScheduleListView(schedules: [UserScheduleItem], embedInScrollView: Bool = true) -> some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .pretendSemiBold(size: 16)
                    }
                    
                    HStack(spacing: 8) {
                        Label(item.displayTime, systemImage: "clock")
                        Label(item.displayPlace, systemImage: "house.circle.fill")
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
        
        if embedInScrollView {
            ScrollView { content }
                .scrollIndicators(.hidden)
        } else {
            content
        }
    }
}
