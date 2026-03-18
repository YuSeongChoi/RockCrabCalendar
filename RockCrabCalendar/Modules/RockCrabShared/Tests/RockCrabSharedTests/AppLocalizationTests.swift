import XCTest
@testable import RockCrabShared

final class AppLocalizationTests: XCTestCase {
    func testSyncPreferredLanguageCodeStoresBundleLanguage() {
        let userDefaults = UserDefaults(suiteName: #function)!
        defer { userDefaults.removePersistentDomain(forName: #function) }

        let didChange = AppLocalization.syncPreferredLanguageCode(
            preferredLanguages: ["en"],
            userDefaults: userDefaults,
            locale: Locale(identifier: "ko_KR")
        )

        XCTAssertTrue(didChange)
        XCTAssertEqual(userDefaults.string(forKey: AppStorageKeys.preferredLanguageCode), "en")
    }

    func testPreferredLanguageCodeUsesStoredValueFirst() {
        let userDefaults = AppGroupUserDefaults.shared
        let original = userDefaults.string(forKey: AppStorageKeys.preferredLanguageCode)
        userDefaults.set("en", forKey: AppStorageKeys.preferredLanguageCode)
        defer {
            if let original {
                userDefaults.set(original, forKey: AppStorageKeys.preferredLanguageCode)
            } else {
                userDefaults.removeObject(forKey: AppStorageKeys.preferredLanguageCode)
            }
        }

        XCTAssertTrue(AppLocalization.prefersEnglish)
    }

    func testSyncPreferredLanguageCodeUsesSelectedAppLanguageOverride() {
        let userDefaults = UserDefaults(suiteName: #function)!
        defer { userDefaults.removePersistentDomain(forName: #function) }

        let didChange = AppLocalization.syncPreferredLanguageCode(
            selectedLanguage: .korean,
            preferredLanguages: ["en"],
            userDefaults: userDefaults,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertTrue(didChange)
        XCTAssertEqual(userDefaults.string(forKey: AppStorageKeys.preferredLanguageCode), "ko")
    }
}
