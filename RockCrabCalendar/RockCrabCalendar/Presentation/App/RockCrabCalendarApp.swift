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
    private let environment: AppEnvironment
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
        let runtimeMode = AppEnvironment.RuntimeMode.resolved()
        self.environment = AppEnvironment.configured(mode: runtimeMode)

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
        AppStartupCoordinator().start()
    }
}

private struct AppStartupCoordinator {
    private let appearanceConfigurator: NavigationBarAppearanceConfiguring
    private let fontRegistrar: AppFontRegistering
    private let notificationRequester: NotificationPermissionRequesting

    init(
        appearanceConfigurator: NavigationBarAppearanceConfiguring = NavigationBarAppearanceConfigurator(),
        fontRegistrar: AppFontRegistering = RockTurtleFontRegistrar(),
        notificationRequester: NotificationPermissionRequesting = UserNotificationPermissionRequester()
    ) {
        self.appearanceConfigurator = appearanceConfigurator
        self.fontRegistrar = fontRegistrar
        self.notificationRequester = notificationRequester
    }

    @MainActor
    func start() {
        appearanceConfigurator.configure()
        fontRegistrar.register()
        notificationRequester.request()
    }
}

private protocol NavigationBarAppearanceConfiguring {
    @MainActor
    func configure()
}

private struct NavigationBarAppearanceConfigurator: NavigationBarAppearanceConfiguring {
    @MainActor
    func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        if let chevron = UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysOriginal) {
            let insetChevron = chevron.withAlignmentRectInsets(.init(top: 0, left: -2, bottom: 0, right: 0))
            appearance.setBackIndicatorImage(insetChevron, transitionMaskImage: insetChevron)
        }

        let back = UIBarButtonItemAppearance(style: .plain)
        back.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = back

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = .label
        navBar.isTranslucent = false
    }
}

private protocol AppFontRegistering {
    func register()
}

private struct RockTurtleFontRegistrar: AppFontRegistering {
    func register() {
        do {
            try RockTurtleCalendarFont.register()
        } catch {
            AppLogger.error("폰트 등록 실패: \(error.localizedDescription)", category: .app)
        }
    }
}

private protocol NotificationPermissionRequesting {
    func request()
}

private struct UserNotificationPermissionRequester: NotificationPermissionRequesting {
    func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.error("알림 권한 요청 실패 : \(error.localizedDescription)", category: .notification)
            } else {
                AppLogger.debug("알림 권한 요청 결과 : \(granted ? "허용된" : "거부됨")", category: .notification)
            }
        }
    }
}
