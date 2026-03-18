import Foundation

public struct AppUpdatePrompt: Equatable {
    public let latestVersion: String
    public let trackViewURL: URL

    public init(latestVersion: String, trackViewURL: URL) {
        self.latestVersion = latestVersion
        self.trackViewURL = trackViewURL
    }
}

public protocol AppStoreVersionProviding {
    func fetchLatestVersion(bundleIdentifier: String) async throws -> AppUpdatePrompt?
}

public struct AppStoreLookupClient: AppStoreVersionProviding {
    private let session: URLSession
    private let fallbackTrackViewURL: URL?

    public init(
        session: URLSession = .shared,
        fallbackTrackViewURL: URL? = nil
    ) {
        self.session = session
        self.fallbackTrackViewURL = fallbackTrackViewURL
    }

    public func fetchLatestVersion(bundleIdentifier: String) async throws -> AppUpdatePrompt? {
        guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleIdentifier)
        ]
        guard let url = components.url else { return nil }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        guard let item = response.results.first else {
            return nil
        }
        let trackViewURL = URL(string: item.trackViewUrl) ?? fallbackTrackViewURL
        guard let trackViewURL else { return nil }

        return AppUpdatePrompt(latestVersion: item.version, trackViewURL: trackViewURL)
    }
}

public final class AppUpdatePromptService {
    private let provider: AppStoreVersionProviding
    private let userDefaults: UserDefaults
    private let nowProvider: () -> Date
    private let checkInterval: TimeInterval
    private let snoozeInterval: TimeInterval

    public init(
        provider: AppStoreVersionProviding = AppStoreLookupClient(),
        userDefaults: UserDefaults = AppGroupUserDefaults.shared,
        nowProvider: @escaping () -> Date = Date.init,
        checkInterval: TimeInterval = 60 * 60 * 24,
        snoozeInterval: TimeInterval = 60 * 60 * 24
    ) {
        self.provider = provider
        self.userDefaults = userDefaults
        self.nowProvider = nowProvider
        self.checkInterval = checkInterval
        self.snoozeInterval = snoozeInterval
    }

    public func checkForUpdate(
        bundleIdentifier: String,
        currentVersion: String
    ) async -> AppUpdatePrompt? {
        let now = nowProvider()
        guard shouldCheck(now: now) else { return nil }
        userDefaults.set(now, forKey: AppStorageKeys.appUpdateLastCheckedAt)

        do {
            guard let prompt = try await provider.fetchLatestVersion(bundleIdentifier: bundleIdentifier) else {
                return nil
            }
            guard Self.isRemoteVersionNewer(prompt.latestVersion, than: currentVersion) else {
                return nil
            }
            guard isSnoozed(prompt.latestVersion, now: now) == false else {
                return nil
            }
            return prompt
        } catch {
            AppLogger.error("업데이트 확인 실패: \(error.localizedDescription)", category: .app)
            return nil
        }
    }

    public func snooze(_ prompt: AppUpdatePrompt) {
        userDefaults.set(prompt.latestVersion, forKey: AppStorageKeys.appUpdateSnoozedVersion)
        userDefaults.set(nowProvider().addingTimeInterval(snoozeInterval), forKey: AppStorageKeys.appUpdateSnoozedUntil)
    }

    public static func isRemoteVersionNewer(_ remoteVersion: String, than currentVersion: String) -> Bool {
        compareVersions(remoteVersion, currentVersion) == .orderedDescending
    }

    private func shouldCheck(now: Date) -> Bool {
        guard let lastCheckedAt = userDefaults.object(forKey: AppStorageKeys.appUpdateLastCheckedAt) as? Date else {
            return true
        }
        return now.timeIntervalSince(lastCheckedAt) >= checkInterval
    }

    private func isSnoozed(_ version: String, now: Date) -> Bool {
        guard let snoozedVersion = userDefaults.string(forKey: AppStorageKeys.appUpdateSnoozedVersion),
              snoozedVersion == version,
              let snoozedUntil = userDefaults.object(forKey: AppStorageKeys.appUpdateSnoozedUntil) as? Date else {
            return false
        }
        return now < snoozedUntil
    }

    private static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0
            if lhsValue < rhsValue { return .orderedAscending }
            if lhsValue > rhsValue { return .orderedDescending }
        }

        return .orderedSame
    }
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupItem]
}

private struct AppStoreLookupItem: Decodable {
    let version: String
    let trackViewUrl: String
}
