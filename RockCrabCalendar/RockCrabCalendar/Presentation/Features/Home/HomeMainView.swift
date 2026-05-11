//
//  HomeMainView.swift
//  RockCrabCalendar
//
//  Created by YuSeongChoi on 11/26/25.
//

import SwiftUI
import RockCrabShared
import RockCrabDomain

struct HomeMainView: View {
    @State private var calendarVM: CalendarViewModel
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel

    @State private var showCategorySheet: Bool = false
    @State private var isFabExpanded: Bool = false
    @State private var viewType: ViewType = .calendar
    @State private var navigationPath: [HomeRoute] = []
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false

    private let scheduleRecordStore: ScheduleRecordStoreProtocol
    private let adRemovalManager: AdRemovalPurchaseManager
    private let interstitialAdService: InterstitialAdService
    private let userScheduleAdCounter: UserScheduleAdCounter

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
        self.scheduleRecordStore = environment.scheduleRecordStore
        self.adRemovalManager = AdRemovalPurchaseManager()
        self.interstitialAdService = InterstitialAdService()
        self.userScheduleAdCounter = UserScheduleAdCounter()
    }

    init(
        calendarVM: CalendarViewModel,
        scheduleVM: QWERScheduleViewModel,
        userVM: UserScheduleViewModel,
        scheduleRecordStore: ScheduleRecordStoreProtocol,
        adRemovalManager: AdRemovalPurchaseManager,
        interstitialAdService: InterstitialAdService,
        userScheduleAdCounter: UserScheduleAdCounter
    ) {
        self.scheduleRecordStore = scheduleRecordStore
        self.adRemovalManager = adRemovalManager
        self.interstitialAdService = interstitialAdService
        self.userScheduleAdCounter = userScheduleAdCounter
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
                            AnalyticsHelper.logAction(
                                actionName: "home_filter_open",
                                label: "홈 필터 열기"
                            )
                            showCategorySheet = true
                        },
                        onToday: {
                            let today = Date()
                            calendarVM.select(date: today)
                            calendarVM.currentMonth = calendarVM.startOfMonth(for: today)
                            scheduleVM.selectedDate = today
                            AnalyticsHelper.logAction(
                                actionName: "home_today_tap",
                                label: "오늘 버튼 선택"
                            )
                        },
                        onSearch: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if viewType == .calendar {
                                    viewType = .list
                                    isSearchExpanded = true
                                } else {
                                    isSearchExpanded.toggle()
                                }
                            }

                            if !isSearchExpanded {
                                searchText = ""
                            }
                            AnalyticsHelper.logAction(
                                actionName: "schedule_search_toggle",
                                label: isSearchExpanded ? "검색 열기" : "검색 닫기",
                                parameters: [
                                    "view_type": viewType.analyticsLabel
                                ]
                            )
                        },
                        onToggleView: {
                            viewType = (viewType == .calendar) ? .list : .calendar
                            if viewType == .calendar {
                                isSearchExpanded = false
                                searchText = ""
                            }
                            AnalyticsHelper.logAction(
                                actionName: "home_view_type_change",
                                label: "홈 보기 방식 변경",
                                parameters: [
                                    "view_type": viewType.analyticsLabel
                                ]
                            )
                        }
                    )

                    if viewType == .list && isSearchExpanded {
                        HomeSearchBarView(text: $searchText)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    switch viewType {
                    case .calendar:
                        CalendarView(
                            calendarVM: calendarVM,
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            onEdit: { mode in
                                logScheduleEditOpen(mode)
                                navigationPath.append(.editSchedule(mode: mode))
                            },
                            onRecord: { target in
                                logRecordEditOpen(target)
                                navigationPath.append(.editRecord(target: target))
                            }
                        )
                    case .list:
                        ScheduleListView(
                            calendarVM: calendarVM,
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            searchText: searchText,
                            onEdit: { mode in
                                logScheduleEditOpen(mode)
                                navigationPath.append(.editSchedule(mode: mode))
                            },
                            onRecord: { target in
                                logRecordEditOpen(target)
                                navigationPath.append(.editRecord(target: target))
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
                        AnalyticsHelper.logAction(
                            actionName: "schedule_create_open",
                            label: "QWER 일정 추가 열기",
                            parameters: ["schedule_kind": "QWER"]
                        )
                        navigationPath.append(.addSchedule(kind: .qwer))
                    },
                    onAddUser: {
                        showCategorySheet = false
                        AnalyticsHelper.logAction(
                            actionName: "schedule_create_open",
                            label: "개인 일정 추가 열기",
                            parameters: ["schedule_kind": "개인"]
                        )
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
                            ),
                            adRemovalManager: adRemovalManager,
                            interstitialAdService: interstitialAdService,
                            userScheduleAdCounter: userScheduleAdCounter
                        )
                    } else {
                        ScheduleEditView(
                            viewModel: ScheduleEditViewModel(
                                kind: .qwer,
                                defaultDate: scheduleVM.selectedDate,
                                qwerVM: scheduleVM,
                                userVM: userVM
                            ),
                            adRemovalManager: adRemovalManager,
                            interstitialAdService: interstitialAdService,
                            userScheduleAdCounter: userScheduleAdCounter
                        )
                    }
                case .editSchedule(let mode):
                    ScheduleEditView(
                        viewModel: ScheduleEditViewModel(
                            mode: mode,
                            defaultDate: scheduleVM.selectedDate,
                            qwerVM: scheduleVM,
                            userVM: userVM
                        ),
                        adRemovalManager: adRemovalManager,
                        interstitialAdService: interstitialAdService,
                        userScheduleAdCounter: userScheduleAdCounter
                    )
                case .editRecord(let target):
                    ScheduleRecordEditView(
                        viewModel: ScheduleRecordEditViewModel(
                            target: target,
                            store: scheduleRecordStore
                        ),
                        adRemovalManager: adRemovalManager,
                        interstitialAdService: interstitialAdService,
                        userScheduleAdCounter: userScheduleAdCounter
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
            AnalyticsHelper.logScreen(
                screenName: "home",
                label: "홈 화면",
                parameters: [
                    "selected_view": viewType.analyticsLabel,
                    "qwer_schedule_count": scheduleVM.schedules.count,
                    "user_schedule_count": userVM.schedules.count
                ]
            )
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryFilterSheet(
                active: scheduleVM.activeCategories,
                onApply: { selected in
                    scheduleVM.setCategories(selected)
                    AnalyticsHelper.logAction(
                        actionName: "home_filter_apply",
                        label: "홈 필터 적용",
                        parameters: [
                            "selected_category_count": selected.count
                        ]
                    )
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
        .onChange(of: viewType) { _, newValue in
            if newValue == .calendar {
                isSearchExpanded = false
                searchText = ""
            }
        }
    }

}

private extension HomeMainView {
    func logScheduleEditOpen(_ mode: ScheduleEditMode) {
        AnalyticsHelper.logAction(
            actionName: "schedule_edit_open",
            label: "일정 수정 열기",
            parameters: [
                "schedule_kind": mode.kind.analyticsLabel,
                "edit_mode": mode.analyticsModeLabel,
                "source_view": viewType.analyticsLabel
            ]
        )
    }

    func logRecordEditOpen(_ target: ScheduleRecordTarget) {
        AnalyticsHelper.logAction(
            actionName: "record_edit_open",
            label: "일정 기록 열기",
            parameters: [
                "schedule_kind": target.kind.analyticsLabel,
                "source_view": viewType.analyticsLabel
            ]
        )
    }
}

extension HomeMainView {
    private enum HomeRoute: Hashable {
        case addSchedule(kind: ScheduleEditKind)
        case editSchedule(mode: ScheduleEditMode)
        case editRecord(target: ScheduleRecordTarget)
    }

    enum ViewType {
        /// 달력
        case calendar
        /// 리스트
        case list

        var analyticsLabel: String {
            switch self {
            case .calendar:
                return "캘린더"
            case .list:
                return "리스트"
            }
        }
    }
}
