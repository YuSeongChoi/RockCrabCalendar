//
//  CustomCalendarView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 3/4/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var calendarVM = CalendarViewModel()
    @State private var scheduleVM = QWERScheduleViewModel()
    @State private var userVM = UserScheduleViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var showCategorySheet: Bool = false
    @State private var addScheduleSheet: Bool = false
    @State private var addKind: ScheduleEditView.Kind = .qwer
    @State private var isFabExpanded: Bool = false
    @State private var viewType: ViewType = .calendar

    @State private var editTarget: ScheduleEditView.Mode? = nil
    
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
    
    private let lastSyncFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd HH:mm"
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
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 10) {
                        dateSelectionView
                        calendarOptionView
                        
                        switch viewType {
                        case .calendar:
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .black : .white }))
                            }
                            
                        case .list:
                            monthListView()
                        }
                    }
                    
                    if isFabExpanded {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) { isFabExpanded = false }
                            }
                    }
                    
                    scheduleFloatingButton
                }
            }
        }
        .background(Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white }))
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.fetchAllSchedules(force: false)
            userVM.fetchAllSchedules()
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryFilterSheet(
                active: scheduleVM.activeCategories,
                onApply: { selected in
                    scheduleVM.setCategories(selected)
                }
            )
        }
        .sheet(isPresented: $addScheduleSheet) {
            if addKind == .user {
                ScheduleEditView(
                    kind: .user,
                    defaultDate: scheduleVM.selectedDate,
                    qwerVM: scheduleVM,
                    userVM: userVM,
                    defaultColor: userVM.schedules.last?.colorHex != nil ? Color(hex: userVM.schedules.last!.colorHex) : .purple
                )
            } else {
                ScheduleEditView(
                    kind: .qwer,
                    defaultDate: scheduleVM.selectedDate,
                    qwerVM: scheduleVM,
                    userVM: userVM
                )
            }
        }
        .onChange(of: addScheduleSheet) { _, newValue in
            if newValue == false {
                // 부분 갱신이 이미 반영되므로 전체 강제 fetch는 피합니다
                scheduleVM.fetchAllSchedules(force: false)
                // userVM은 로컬 변경 시 바로 schedules에 반영되므로 fetch 생략 가능
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
                    .background(Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 })))
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
                    .background(Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 })))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Group {
                switch viewType {
                case .calendar:
                    Button {
                        viewType = .list
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                case .list:
                    Button {
                        viewType = .calendar
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .pretendSemiBold(size: 14)
            .padding(6)
            .animation(.easeInOut(duration: 0.25), value: viewType)
            .background(Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 })))
            .foregroundColor(.primary)

            Button {
                scheduleVM.fetchAllSchedules(force: true)
                userVM.fetchAllSchedules()
            } label: {
                Image(systemName: "arrow.circlepath")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 })))
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
                        eventColors: combinedEventColors(for: date)
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
    
    // MARK: - User Schedule Repeat Helpers
    private func userHasEvent(on date: Date) -> Bool {
        return userVM.schedules.contains { occursOnDate($0, on: date) }
    }

    private func userSchedules(on date: Date) -> [UserScheduleItem] {
        userVM.schedules.compactMap { item in
            occursOnDate(item, on: date) ? UserScheduleItem(
                id: item.id,
                title: item.title,
                date: Calendar.current.startOfDay(for: date),
                time: item.time,
                place: item.place,
                isRepeat: item.isRepeat,
                repeatType: item.repeatType,
                repeatEndDate: item.repeatEndDate
            ) : nil
        }
    }

    private func occursOnDate(_ item: UserScheduleItem, on target: Date) -> Bool {
        let cal = Calendar.current
        let start = cal.startOfDay(for: item.date)
        let t = cal.startOfDay(for: target)

        // Non-repeating
        if !item.isRepeat || item.repeatType == .none {
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
                        .fill(Color(UIColor { trait in
                            trait.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6
                        }))
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
                        .fill(Color(UIColor { trait in
                            trait.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6
                        }))
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
    
    @ViewBuilder
    private func monthListView() -> some View {
        let qwerMonth = monthSchedulesForCurrentMonth()
        let userMonth = monthUserSchedulesForCurrentMonth()
        if qwerMonth.isEmpty && userMonth.isEmpty {
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
            let groupedQ = Dictionary(grouping: qwerMonth) { calendar.startOfDay(for: $0.date) }
            let groupedU = Dictionary(grouping: userMonth) { calendar.startOfDay(for: $0.date) }
            let days = Set(groupedQ.keys).union(groupedU.keys).sorted()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(days, id: \.self) { day in
                        Text(dayLabelFormatter.string(from: day))
                            .pretendSemiBold(size: 16)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        if let qItems = groupedQ[day] {
                            scheduleListView(schedules: qItems, embedInScrollView: false)
                        }
                        if let uItems = groupedU[day] {
                            userScheduleListView(schedules: uItems, embedInScrollView: false)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .transition(.opacity)
        }
    }
    
    // MARK: Floating Button View
    @ViewBuilder
    private var scheduleFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    if isFabExpanded {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isFabExpanded = false }
                            addKind = .qwer
                            addScheduleSheet = true
                        } label: {
                            Label("QWER 스케줄", systemImage: "person.3.fill")
                                .labelStyle(.titleAndIcon)
                                .pretendSemiBold(size: 14)
                                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                .background(
                                    Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 }))
                                )
                                .foregroundColor(.primary)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isFabExpanded = false }
                            addKind = .user
                            addScheduleSheet = true
                        } label: {
                            Label("개인 스케줄", systemImage: "person.fill")
                                .labelStyle(.titleAndIcon)
                                .pretendSemiBold(size: 14)
                                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                .background(
                                    Capsule().fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 }))
                                )
                                .foregroundColor(.primary)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isFabExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isFabExpanded ? "xmark.circle" : "plus.circle")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color(UIColor {
                                $0.userInterfaceStyle == .dark ? .RGB_173 : .black
                            }))
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 15)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isFabExpanded)
        }
    }
}

extension CalendarView {
    enum ViewType {
        /// 달력
        case calendar
        /// 리스트
        case list
    }
}
