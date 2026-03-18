import XCTest
@testable import RockCrabShared

final class AppUpdatePromptServiceTests: XCTestCase {
    func testRemoteNewerVersionReturnsPrompt() async {
        let defaults = makeDefaults(name: #function)
        let provider = MockAppStoreVersionProvider(
            prompt: AppUpdatePrompt(
                latestVersion: "1.2.0",
                trackViewURL: URL(string: "https://apps.apple.com/app/id123456789")!
            )
        )
        let service = AppUpdatePromptService(
            provider: provider,
            userDefaults: defaults,
            nowProvider: { Date(timeIntervalSince1970: 1_000) },
            checkInterval: 0
        )

        let prompt = await service.checkForUpdate(
            bundleIdentifier: "ys.RockCrabCalendar",
            currentVersion: "1.1.0"
        )

        XCTAssertEqual(prompt?.latestVersion, "1.2.0")
    }

    func testSnoozedSameVersionSuppressesPrompt() async {
        let defaults = makeDefaults(name: #function)
        let now = Date(timeIntervalSince1970: 1_000)
        let prompt = AppUpdatePrompt(
            latestVersion: "1.2.0",
            trackViewURL: URL(string: "https://apps.apple.com/app/id123456789")!
        )
        let provider = MockAppStoreVersionProvider(prompt: prompt)
        let service = AppUpdatePromptService(
            provider: provider,
            userDefaults: defaults,
            nowProvider: { now },
            checkInterval: 0,
            snoozeInterval: 60 * 60
        )

        service.snooze(prompt)
        let result = await service.checkForUpdate(
            bundleIdentifier: "ys.RockCrabCalendar",
            currentVersion: "1.1.0"
        )

        XCTAssertNil(result)
    }

    func testNewerVersionBypassesOldSnooze() async {
        let defaults = makeDefaults(name: #function)
        let now = Date(timeIntervalSince1970: 1_000)
        let oldPrompt = AppUpdatePrompt(
            latestVersion: "1.2.0",
            trackViewURL: URL(string: "https://apps.apple.com/app/id123456789")!
        )
        let provider = MockAppStoreVersionProvider(
            prompt: AppUpdatePrompt(
                latestVersion: "1.3.0",
                trackViewURL: URL(string: "https://apps.apple.com/app/id123456789")!
            )
        )
        let service = AppUpdatePromptService(
            provider: provider,
            userDefaults: defaults,
            nowProvider: { now },
            checkInterval: 0,
            snoozeInterval: 60 * 60
        )

        service.snooze(oldPrompt)
        let result = await service.checkForUpdate(
            bundleIdentifier: "ys.RockCrabCalendar",
            currentVersion: "1.1.0"
        )

        XCTAssertEqual(result?.latestVersion, "1.3.0")
    }

    func testCheckIntervalSkipsRepeatedLookup() async {
        let defaults = makeDefaults(name: #function)
        let provider = MockAppStoreVersionProvider(
            prompt: AppUpdatePrompt(
                latestVersion: "1.2.0",
                trackViewURL: URL(string: "https://apps.apple.com/app/id123456789")!
            )
        )
        let now = Date(timeIntervalSince1970: 1_000)
        let service = AppUpdatePromptService(
            provider: provider,
            userDefaults: defaults,
            nowProvider: { now },
            checkInterval: 60 * 60
        )

        _ = await service.checkForUpdate(
            bundleIdentifier: "ys.RockCrabCalendar",
            currentVersion: "1.1.0"
        )
        let secondResult = await service.checkForUpdate(
            bundleIdentifier: "ys.RockCrabCalendar",
            currentVersion: "1.1.0"
        )

        XCTAssertEqual(provider.callCount, 1)
        XCTAssertNil(secondResult)
    }

    func testVersionComparisonUsesNumericSegments() {
        XCTAssertTrue(AppUpdatePromptService.isRemoteVersionNewer("1.1.10", than: "1.1.8"))
        XCTAssertTrue(AppUpdatePromptService.isRemoteVersionNewer("2.0", than: "1.9.9"))
        XCTAssertFalse(AppUpdatePromptService.isRemoteVersionNewer("1.2.0", than: "1.2"))
    }

    private func makeDefaults(name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

private final class MockAppStoreVersionProvider: AppStoreVersionProviding {
    private let prompt: AppUpdatePrompt?
    private(set) var callCount = 0

    init(prompt: AppUpdatePrompt?) {
        self.prompt = prompt
    }

    func fetchLatestVersion(bundleIdentifier: String) async throws -> AppUpdatePrompt? {
        callCount += 1
        return prompt
    }
}
