//
//  RockTurtleCalendarApp.swift
//  RockTurtleCalendar
//
//  Created by YuSeongChoi on 9/25/24.
//

import SwiftUI
import UIKit
import UserNotifications
import WidgetKit
import RockCrabShared

@main
struct RockCrabCalendarApp: App {
    private static let appStoreURL = URL(string: "https://apps.apple.com/app/id6752741744")!

    private enum AppTab: Hashable {
        case home
        case record
        case settings
    }

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage(AppStorageKeys.preferredAppLanguage, store: AppGroupUserDefaults.shared)
    private var preferredAppLanguageRaw = AppLanguageOption.system.rawValue
    private let environment: AppEnvironment
    private let appUpdateService: AppUpdatePromptService
    @State private var adRemovalManager: AdRemovalPurchaseManager
    @State private var interstitialAdService: InterstitialAdService
    private let userScheduleAdCounter: UserScheduleAdCounter
    @State private var calendarVM: CalendarViewModel
    @State private var scheduleVM: QWERScheduleViewModel
    @State private var userVM: UserScheduleViewModel
    @State private var selectedTab: AppTab = .home
    @State private var appUpdatePrompt: AppUpdatePrompt?
    @State private var hasCheckedForUpdate = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appDelegate.showIndicator {
                    LoadingIndicatorView()
                }
                WindowAlertHostingView()
                
                VStack(spacing: 0) {
                    TabView(selection: $selectedTab) {
                        HomeMainView(
                            calendarVM: calendarVM,
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            scheduleRecordStore: environment.scheduleRecordStore,
                            adRemovalManager: adRemovalManager,
                            interstitialAdService: interstitialAdService,
                            userScheduleAdCounter: userScheduleAdCounter
                        )
                        .tabItem {
                            Label("홈", systemImage: "calendar")
                        }
                        .tag(AppTab.home)

                        ScheduleRecordListView(store: environment.scheduleRecordStore)
                            .tabItem {
                                Label("기록", systemImage: "book.closed")
                            }
                            .tag(AppTab.record)

                        SettingsView(
                            scheduleVM: scheduleVM,
                            userVM: userVM,
                            adRemovalManager: adRemovalManager
                        )
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                        .tag(AppTab.settings)
                    }
                    .tint(Color.textColor)

                    if !adRemovalManager.isAdsRemoved {
                        BannerAdView()
                            .frame(width: 320, height: 50)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.appBackground)
                    }
                }
            }
            .environmentObject(appDelegate)
            .environment(\.locale, AppLocalization.locale(for: selectedAppLanguage))
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .task {
                await checkForUpdateIfNeeded()
                await adRemovalManager.refresh()
                await interstitialAdService.preload()
            }
            .onChange(of: preferredAppLanguageRaw) { _, newValue in
                let selectedLanguage = AppLanguageOption(rawValue: newValue) ?? .system
                let didUpdatePreferredLanguage = AppLocalization.syncPreferredLanguageCode(
                    selectedLanguage: selectedLanguage
                )
                if didUpdatePreferredLanguage {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                AnalyticsHelper.logAction(
                    actionName: "tab_selected",
                    label: "탭 선택",
                    parameters: [
                        "tab_name": tabLabel(for: newValue)
                    ]
                )
            }
            .alert(updatePromptTitle, isPresented: isShowingUpdatePrompt) {
                Button(updateLaterTitle, role: .cancel) {
                    guard let prompt = appUpdatePrompt else { return }
                    appUpdateService.snooze(prompt)
                    appUpdatePrompt = nil
                }
                Button(updateNowTitle) {
                    openAppStoreForUpdate()
                }
            } message: {
                Text(updatePromptMessage)
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
        let selectedLanguage = AppLanguageOption(
            rawValue: sharedDefaults.string(forKey: AppStorageKeys.preferredAppLanguage) ?? ""
        ) ?? .system
        let didUpdatePreferredLanguage = AppLocalization.syncPreferredLanguageCode(
            selectedLanguage: selectedLanguage,
            userDefaults: sharedDefaults
        )
        self.environment = AppEnvironment.configured(mode: runtimeMode, userDefaults: sharedDefaults)
        self.appUpdateService = AppUpdatePromptService(
            provider: AppStoreLookupClient(fallbackTrackViewURL: Self.appStoreURL),
            userDefaults: sharedDefaults
        )
        self.userScheduleAdCounter = UserScheduleAdCounter(userDefaults: sharedDefaults)

        _adRemovalManager = State(initialValue: AdRemovalPurchaseManager(userDefaults: sharedDefaults))
        _interstitialAdService = State(initialValue: InterstitialAdService())
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
        if didUpdatePreferredLanguage {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private var selectedAppLanguage: AppLanguageOption {
        AppLanguageOption(rawValue: preferredAppLanguageRaw) ?? .system
    }

    private var isShowingUpdatePrompt: Binding<Bool> {
        Binding(
            get: { appUpdatePrompt != nil },
            set: { isPresented in
                if isPresented == false {
                    appUpdatePrompt = nil
                }
            }
        )
    }

    private var updatePromptTitle: String {
        AppLocalization.localized(ko: "업데이트 가능", en: "Update Available")
    }

    private var updatePromptMessage: String {
        guard let prompt = appUpdatePrompt else { return "" }
        return String.localizedStringWithFormat(
            AppLocalization.localized(
                ko: "새 버전 %@가 출시되었습니다. 지금 업데이트할까요?",
                en: "Version %@ is available. Update now?"
            ),
            prompt.latestVersion
        )
    }

    private var updateLaterTitle: String {
        AppLocalization.localized(ko: "나중에", en: "Later")
    }

    private var updateNowTitle: String {
        AppLocalization.localized(ko: "업데이트", en: "Update")
    }

    private func tabLabel(for tab: AppTab) -> String {
        switch tab {
        case .home:
            return "홈"
        case .record:
            return "기록"
        case .settings:
            return "설정"
        }
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

    @MainActor
    private func checkForUpdateIfNeeded() async {
        guard hasCheckedForUpdate == false else { return }
        hasCheckedForUpdate = true

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              currentVersion.isEmpty == false else {
            return
        }

        appUpdatePrompt = await appUpdateService.checkForUpdate(
            bundleIdentifier: bundleIdentifier,
            currentVersion: currentVersion
        )
    }

    private func openAppStoreForUpdate() {
        guard let trackViewURL = appUpdatePrompt?.trackViewURL else { return }
        UIApplication.shared.open(trackViewURL)
        appUpdatePrompt = nil
    }
}

private struct AppStartupCoordinator {
    private let appearanceConfigurator: NavigationBarAppearanceConfiguring
    private let tabBarAppearanceConfigurator: TabBarAppearanceConfiguring
    private let fontRegistrar: AppFontRegistering
    private let notificationRequester: NotificationPermissionRequesting

    init(
        appearanceConfigurator: NavigationBarAppearanceConfiguring = NavigationBarAppearanceConfigurator(),
        tabBarAppearanceConfigurator: TabBarAppearanceConfiguring = TabBarAppearanceConfigurator(),
        fontRegistrar: AppFontRegistering = RockTurtleFontRegistrar(),
        notificationRequester: NotificationPermissionRequesting = UserNotificationPermissionRequester()
    ) {
        self.appearanceConfigurator = appearanceConfigurator
        self.tabBarAppearanceConfigurator = tabBarAppearanceConfigurator
        self.fontRegistrar = fontRegistrar
        self.notificationRequester = notificationRequester
    }

    @MainActor
    func start() {
        appearanceConfigurator.configure()
        tabBarAppearanceConfigurator.configure()
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

private protocol TabBarAppearanceConfiguring {
    @MainActor
    func configure()
}

private struct TabBarAppearanceConfigurator: TabBarAppearanceConfiguring {
    @MainActor
    func configure() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance]
            .forEach { itemAppearance in
                itemAppearance.selected.iconColor = .label
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.label]
                itemAppearance.normal.iconColor = .secondaryLabel
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
            }

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .label
        tabBar.unselectedItemTintColor = .secondaryLabel
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
