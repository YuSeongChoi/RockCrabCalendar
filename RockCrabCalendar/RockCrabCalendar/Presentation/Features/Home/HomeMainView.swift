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
                        HomeDateSelectionView(
                            currentMonth: calendarVM.currentMonth,
                            onPrev: { calendarVM.changeMonth(by: -1) },
                            onNext: { calendarVM.changeMonth(by: 1) }
                        )
                        HomeCalendarOptionView(
                            viewType: viewType,
                            onShowFilter: { showCategorySheet = true },
                            onToday: {
                                let today = Date()
                                calendarVM.select(date: today)
                                calendarVM.currentMonth = calendarVM.startOfMonth(for: today)
                                scheduleVM.selectedDate = today
                            },
                            onToggleView: {
                                viewType = (viewType == .calendar) ? .list : .calendar
                            },
                            onRefresh: {
                                scheduleVM.fetchAllSchedules(force: true)
                                userVM.fetchAllSchedules()
                            }
                        )
                        
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
                    
                    HomeScheduleFloatingButton(
                        isExpanded: $isFabExpanded,
                        onAddQWER: {
                            addKind = .qwer
                            addScheduleSheet = true
                        },
                        onAddUser: {
                            addKind = .user
                            addScheduleSheet = true
                        }
                    )
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
    
}

extension HomeMainView {
    enum ViewType {
        /// 달력
        case calendar
        /// 리스트
        case list
    }
}
