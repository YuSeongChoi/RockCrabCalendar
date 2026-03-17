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
    private enum AppTab: Hashable {
        case home
        case settings
    }

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let environment: AppEnvironment
    @State private var calendarVM: CalendarViewModel
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel
    @State private var selectedTab: AppTab = .home
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appDelegate.showIndicator {
                    LoadingIndicatorView()
                }
                WindowAlertHostingView()
                
                TabView(selection: $selectedTab) {
                    HomeMainView(
                        calendarVM: calendarVM,
                        scheduleVM: scheduleVM,
                        userVM: userVM
                    )
                    .tabItem {
                        Label("홈", systemImage: "calendar")
                    }
                    .tag(AppTab.home)

                    SettingsView(scheduleVM: scheduleVM, userVM: userVM)
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                        .tag(AppTab.settings)
                }
            }
            .environmentObject(appDelegate)
            .environment(\.locale, .autoupdatingCurrent)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    @MainActor
    init() {
        let runtimeMode = AppEnvironment.RuntimeMode.resolved()
        let sharedDefaults = AppGroupUserDefaults.shared
        AppGroupUserDefaults.migrateFromStandardIfNeeded(
            keys: AppStorageKeys.appGroupMigrationKeys,
            target: sharedDefaults
        )
        self.environment = AppEnvironment.configured(mode: runtimeMode, userDefaults: sharedDefaults)

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

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "rockcrabcalendar" else { return }

        let targetDate = parseDateFromDeepLink(url) ?? Date()
        selectedTab = .home
        calendarVM.select(date: targetDate)
        calendarVM.currentMonth = calendarVM.startOfMonth(for: targetDate)
        scheduleVM.selectedDate = targetDate
    }

    private func parseDateFromDeepLink(_ url: URL) -> Date? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard components.host == "calendar" else { return nil }
        guard let dateString = components.queryItems?.first(where: { $0.name == "date" })?.value else {
            return nil
        }

        let formatter = AppDateFormatterFactory.fixedDayKeyFormatter()
        return formatter.date(from: dateString)
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
