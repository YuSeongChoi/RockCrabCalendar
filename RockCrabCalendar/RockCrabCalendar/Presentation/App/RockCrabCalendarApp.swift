//
//  RockTurtleCalendarApp.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI
import UserNotifications
import RockCrabShared

@main
struct RockCrabCalendarApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let environment = AppEnvironment.live()
    @State private var calendarVM: CalendarViewModel
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appDelegate.showIndicator {
                    LoadingIndicatorView()
                }
                WindowAlertHostingView()
                
                TabView {
                    HomeMainView(
                        calendarVM: calendarVM,
                        scheduleVM: scheduleVM,
                        userVM: userVM
                    )
                    .tabItem {
                        Label("홈", systemImage: "calendar")
                    }

                    SettingsView(scheduleVM: scheduleVM, userVM: userVM)
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                }
            }
            .environmentObject(appDelegate)
            .environment(\.locale, .autoupdatingCurrent)
        }
    }
    
    @MainActor
    init() {
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

        // 1) 전역 네비게이션 바 Appearance 구성
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground() // 불투명 배경 (투명 스크롤 이슈 방지)
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label,
                                          .font: UIFont.boldSystemFont(ofSize: 17)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        // 2) Back indicator 아이콘 명시적으로 지정 (SF Symbol 추천)
        if let chevron = UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysOriginal) {
            // alignment inset이 필요하면 여기서 조절
            let insetChevron = chevron.withAlignmentRectInsets(.init(top: 0, left: -2, bottom: 0, right: 0))
            appearance.setBackIndicatorImage(insetChevron, transitionMaskImage: insetChevron)
        }

        // 3) Back 버튼 타이틀 스타일(전역) — 완전 제거는 per-view .minimal 권장
        let back = UIBarButtonItemAppearance(style: .plain)
        back.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = back

        // 4) 모든 상태에 동일 적용
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = .label // back 아이콘/바튼 색
        navBar.isTranslucent = false

        // (선택) iOS 17 네비 바 배경과 동기화하고 싶으면, 뷰단에서 .toolbarBackground(...)도 같이 써줘

        do {
            try RockTurtleCalendarFont.register()
        } catch {
            AppLogger.error("폰트 등록 실패: \(error.localizedDescription)", category: .app)
        }
        
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.error("알림 권한 요청 실패 : \(error.localizedDescription)", category: .notification)
            } else {
                AppLogger.debug("알림 권한 요청 결과 : \(granted ? "허용된" : "거부됨")", category: .notification)
            }
        }
    }
}
