//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var calendarVM = CalendarViewModel()
    @State private var scheduleVM = ScheduleViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var showCategorySheet: Bool = false
    @State private var showMonthList: Bool = false
    
    private let calendar = Calendar.current
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    private let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일(E)"
        return f
    }()
    private let daysOfWeek = ["일", "월", "화", "수", "목", "금", "토"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    dateSelectionView
                    calendarOptionView
                    if showMonthList {
                        monthListView()
                    } else {
                        dateHeaderView
                        dateGridView(availableWidth: geometry.size.width)
                        
                        // 최근 동기화 캡션
                        Text("\(scheduleVM.lastSyncText)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                        Divider()
                    }
                }
                .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white }))
                
                if showMonthList {
                    EmptyView()
                } else {
                    let selectedDateSchedules = scheduleVM.schedules(on: scheduleVM.selectedDate)
                    if !selectedDateSchedules.isEmpty {
                        scheduleListView(schedules: selectedDateSchedules)
                            .padding(.top, 12)
                    } else {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                            Text("일정이 없습니다")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white }))
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.fetchAllSchedules(force: false)
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryFilterSheet(
                active: scheduleVM.activeCategories,
                onApply: { selected in
                    scheduleVM.setCategories(selected)
                }
            )
        }
    }
    
    // MARK: 월 선택뷰
    @ViewBuilder
    private var dateSelectionView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    calendarVM.changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                
                Text(monthYearFormatter.string(from: calendarVM.currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                Button {
                    calendarVM.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            .foregroundStyle(.primary)
            
            Divider()
        }
    }
    
    // MARK: 캘린더 옵션 뷰
    @ViewBuilder
    private var calendarOptionView: some View {
        HStack {
            Button {
                showCategorySheet = true
            } label: {
                Label("필터", systemImage: "line.3.horizontal.decrease.circle")
                    .labelStyle(.titleAndIcon)
                    .pretendSemiBold(size: 14)
                    .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .background(Capsule().fill(Color(UIColor.systemGray5)))
                    .foregroundColor(.primary)
            }
            Spacer()
            Button {
                let today = Date()
                calendarVM.select(date: today)
                calendarVM.currentMonth = calendarVM.startOfMonth(for: today)
                scheduleVM.selectedDate = today
            } label: {
                Text("오늘")
                    .pretendSemiBold(size: 14)
                    .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .background(Capsule().fill(Color(UIColor.systemGray5)))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showMonthList.toggle()
                }
            } label: {
                Image(systemName: showMonthList ? "calendar" : "list.bullet.rectangle")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color(UIColor.systemGray5)))
                    .foregroundColor(.primary)
            }

            // Add NavigationLink to YouTubeTestView
            NavigationLink(destination: YouTubeListView()) {
                Image(systemName: "play.rectangle")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color(UIColor.systemGray5)))
                    .foregroundColor(.primary)
            }

            Button {
                scheduleVM.fetchAllSchedules(force: true)
            } label: {
                Image(systemName: "arrow.circlepath")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color(UIColor.systemGray5)))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
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
                        eventColors: scheduleVM.eventColors(for: date)
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
            .frame(height: totalGridHeight)
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // 수평 스와이프만 인식 (수직 드래그는 무시)
                    if abs(value.translation.height) < 40 { dragOffset = value.translation.width }
                }
                .onEnded { value in
                    defer { dragOffset = 0 }
                    guard abs(value.translation.height) < 40 else { return }
                    let dx = value.translation.width
                    if dx < -50 {
                        calendarVM.changeMonth(by: 1)
                    } else if dx > 50 {
                        calendarVM.changeMonth(by: -1)
                    }
                }
        )
    }
    
    // MARK: 스케줄 리스트 뷰
    @ViewBuilder
    private func scheduleListView(schedules: [ScheduleItem], embedInScrollView: Bool = true) -> some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            ForEach(schedules, id: \.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .pretendSemiBold(size: 16)
                    
                    HStack(spacing: 8) {
                        if !item.time.isEmpty { Label(item.time, systemImage: "clock") }
                        if !item.place.isEmpty { Label(item.place, systemImage: "house.circle.fill") }
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
                        .fill(Color(UIColor { trait in
                            trait.userInterfaceStyle == .dark ? .systemGray5 : .secondarySystemBackground
                        }))
                )
                .padding(.horizontal, 10)
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
    
    private func monthSchedulesForCurrentMonth() -> [ScheduleItem] {
        let start = calendarVM.startOfMonth(for: calendarVM.currentMonth)
        let end = calendarVM.endOfMonth(for: calendarVM.currentMonth)
        return scheduleVM.schedules.filter { item in
            item.date >= start && item.date <= end && scheduleVM.activeCategories.contains(item.category)
        }.sorted { $0.date < $1.date }
    }
    
    @ViewBuilder
    private func monthListView() -> some View {
        let monthItems = monthSchedulesForCurrentMonth()
        if monthItems.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.tertiary)
                Text("이번 달 일정이 없습니다")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else {
            // 같은 날짜끼리 섹션으로 묶어서 표시
            let grouped = Dictionary(grouping: monthItems) { item in
                calendar.startOfDay(for: item.date)
            }
            let days = grouped.keys.sorted()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(days, id: \.self) { day in
                        Text(dayLabelFormatter.string(from: day))
                            .pretendSemiBold(size: 16)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        // 카드 리스트(스크롤뷰 없이 재사용)
                        if let items = grouped[day] {
                            scheduleListView(schedules: items, embedInScrollView: false)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .transition(.opacity)
        }
    }
    
    private struct CategoryFilterSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var selected: Set<ScheduleCategory>
        let onApply: (Set<ScheduleCategory>) -> Void

        init(active: Set<ScheduleCategory>,
             onApply: @escaping (Set<ScheduleCategory>) -> Void) {
            _selected = State(initialValue: active)
            self.onApply = onApply
        }

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        // 전체 선택 (토글)
                        Button {
                            if selected.count == ScheduleCategory.allCases.count {
                                selected.removeAll()
                            } else {
                                selected = Set(ScheduleCategory.allCases)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                let allSelected = selected.count == ScheduleCategory.allCases.count
                                Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(allSelected ? .blue : .secondary)
                                Text("전체 선택")
                                Spacer()
                            }
                        }
                        
                        ForEach(Array(ScheduleCategory.allCases), id: \.self) { cat in
                            HStack(spacing: 10) {
                                Image(systemName: selected.contains(cat) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(cat) ? .blue : .secondary)
                                Text(cat.rawValue)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selected.contains(cat) { selected.remove(cat) }
                                else { selected.insert(cat) }
                            }
                        }
                    }
                }
                .pretendSemiBold(size: 16)
                .foregroundStyle(.secondary)
                .listStyle(.insetGrouped)
                .navigationTitle("분류")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("적용") {
                            onApply(selected)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
