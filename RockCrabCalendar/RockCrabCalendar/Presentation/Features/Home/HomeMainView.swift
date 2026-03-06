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
    
    @State private var showCategorySheet: Bool = false
    @State private var isFabExpanded: Bool = false
    @State private var viewType: ViewType = .calendar
    @State private var navigationPath: [HomeRoute] = []
    
    // Inject environment to build ViewModels with use-cases.
    init(environment: AppEnvironment = .live()) {
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

    init(
        calendarVM: CalendarViewModel,
        scheduleVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel
    ) {
        _calendarVM = State(initialValue: calendarVM)
        _scheduleVM = State(initialValue: scheduleVM)
        _userVM = State(initialValue: userVM)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    HomeDateSelectionView(
                        currentMonth: calendarVM.currentMonth,
                        onPrev: { calendarVM.changeMonth(by: -1) },
                        onNext: { calendarVM.changeMonth(by: 1) }
                    )
                    HomeCalendarOptionView(
                        viewType: viewType,
                        onShowFilter: {
                            showCategorySheet = true
                        },
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
                            scheduleVM.loadCachedAndLocalSchedules()
                            userVM.fetchAllSchedules()
                        }
                    )
                    
                    switch viewType {
                    case .calendar:
                        CalendarView(
                            calendarVM: calendarVM,
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            onEdit: { mode in
                                navigationPath.append(.editSchedule(mode: mode))
                            }
                        )
                    case .list:
                        ScheduleListView(
                            calendarVM: calendarVM,
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            onEdit: { mode in
                                navigationPath.append(.editSchedule(mode: mode))
                            }
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
                        showCategorySheet = false
                        navigationPath.append(.addSchedule(kind: .qwer))
                    },
                    onAddUser: {
                        showCategorySheet = false
                        navigationPath.append(.addSchedule(kind: .user))
                    }
                )
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .addSchedule(let kind):
                    if kind == .user {
                        ScheduleEditView(
                            viewModel: ScheduleEditViewModel(
                                kind: .user,
                                defaultDate: scheduleVM.selectedDate,
                                qwerVM: scheduleVM,
                                userVM: userVM,
                                defaultColor: userVM.schedules.last?.colorHex != nil
                                    ? Color(hex: userVM.schedules.last!.colorHex)
                                    : .purple
                            )
                        )
                    } else {
                        ScheduleEditView(
                            viewModel: ScheduleEditViewModel(
                                kind: .qwer,
                                defaultDate: scheduleVM.selectedDate,
                                qwerVM: scheduleVM,
                                userVM: userVM
                            )
                        )
                    }
                case .editSchedule(let mode):
                    ScheduleEditView(
                        viewModel: ScheduleEditViewModel(
                            mode: mode,
                            defaultDate: scheduleVM.selectedDate,
                            qwerVM: scheduleVM,
                            userVM: userVM
                        )
                    )
                }
            }
        }
        .toolbar(navigationPath.isEmpty ? .visible : .hidden, for: .tabBar)
        .task {
            let year = Calendar.current.component(.year, from: Date())
            await calendarVM.fetchHolidayOnce(baseYear: year)
        }
        .onAppear {
            scheduleVM.selectedDate = calendarVM.selectedDate
            scheduleVM.loadCachedAndLocalSchedules()
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
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.7)])
        }
        .onChange(of: navigationPath) { _, newValue in
            if newValue.isEmpty {
                // 부분 갱신이 이미 반영되므로 캐시+로컬 동기화만 수행합니다.
                scheduleVM.loadCachedAndLocalSchedules()
                // userVM은 로컬 변경 시 바로 schedules에 반영되므로 fetch 생략 가능
            }
        }
    }
    
}

extension HomeMainView {
    private enum HomeRoute: Hashable {
        case addSchedule(kind: ScheduleEditKind)
        case editSchedule(mode: ScheduleEditMode)
    }

    enum ViewType {
        /// 달력
        case calendar
        /// 리스트
        case list
    }
}
