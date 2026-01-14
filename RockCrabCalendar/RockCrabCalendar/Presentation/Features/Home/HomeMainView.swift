//
//  HomeMainView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 11/26/25.
//

import SwiftUI
import RockCrabShared

struct HomeMainView: View {
    @State private var calendarVM: CalendarViewModel
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel

    private let environment: AppEnvironment
    
    @State private var dragOffset: CGFloat = 0
    @State private var showCategorySheet: Bool = false
    @State private var addScheduleSheet: Bool = false
    @State private var addKind: ScheduleEditView.Kind = .qwer
    @State private var isFabExpanded: Bool = false
    @State private var viewType: ViewType = .calendar
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = AppDateFormats.monthTitle
        return formatter
    }()

    // Inject environment to build ViewModels with use-cases.
    init(environment: AppEnvironment = .live()) {
        self.environment = environment
        _calendarVM = State(initialValue: CalendarViewModel(
            holidayUseCase: environment.holidayUseCase,
            holidayStore: environment.holidayStore
        ))
        _scheduleVM = State(initialValue: QWERScheduleViewModel(
            useCase: environment.qwerScheduleUseCase,
            cacheStore: environment.scheduleCacheStore
        ))
        _userVM = State(initialValue: UserScheduleViewModel(
            useCase: environment.userScheduleUseCase,
            migrationStore: environment.userScheduleMigrationStore
        ))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 10) {
                        dateSelectionView
                        calendarOptionView
                        
                        switch viewType {
                        case .calendar:
                            CalendarView(
                                calendarVM: calendarVM,
                                scheduleVM: scheduleVM,
                                userVM: userVM
                            )
                        case .list:
                            ScheduleListView(
                                calendarVM: calendarVM,
                                scheduleVM: scheduleVM,
                                userVM: userVM
                            )
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
        .background(Color.appBackground)
        .task {
            let year = Calendar.current.component(.year, from: Date())
            await calendarVM.fetchHolidayOnce(baseYear: year)
        }
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.fetchAllSchedules(force: false)
            userVM.fetchAllSchedules()
            AnalyticsHelper.logEvent(eventName: "main_screen", parameters: ["label":"메인화면"])
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
                    .background(Capsule().fill(Color.pillBackground))
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
                    .background(Capsule().fill(Color.pillBackground))
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
            .background(Capsule().fill(Color.pillBackground))
            .foregroundColor(.primary)
            
            Button {
                scheduleVM.fetchAllSchedules(force: true)
                userVM.fetchAllSchedules()
            } label: {
                Image(systemName: "arrow.circlepath")
                    .pretendSemiBold(size: 14)
                    .padding(6)
                    .background(Capsule().fill(Color.pillBackground))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
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
                                    Capsule().fill(Color.pillBackground)
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
                                    Capsule().fill(Color.pillBackground)
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

extension HomeMainView {
    enum ViewType {
        /// 달력
        case calendar
        /// 리스트
        case list
    }
}
