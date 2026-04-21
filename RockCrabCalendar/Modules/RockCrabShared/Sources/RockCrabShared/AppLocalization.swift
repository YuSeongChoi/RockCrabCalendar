import Foundation

public enum AppLocalization {
    public static var locale: Locale {
        Locale(identifier: preferredLanguageCode)
    }

    public static var selectedAppLanguage: AppLanguageOption {
        let rawValue = AppGroupUserDefaults.shared.string(forKey: AppStorageKeys.preferredAppLanguage)
        return AppLanguageOption(rawValue: rawValue ?? "") ?? .system
    }

    public static var preferredLanguageCode: String {
        if let storedLanguage = AppGroupUserDefaults.shared.string(forKey: AppStorageKeys.preferredLanguageCode),
           storedLanguage.isEmpty == false {
            return storedLanguage
        }

        return resolvePreferredLanguageCode()
    }

    public static var prefersEnglish: Bool {
        preferredLanguageCode.lowercased().hasPrefix("en")
    }

    public static var showsKoreanHolidays: Bool {
        !prefersEnglish
    }

    public static func localized(ko: String, en: String) -> String {
        prefersEnglish ? en : ko
    }

    public static func locale(
        for selectedLanguage: AppLanguageOption,
        bundle: Bundle = .main,
        preferredLanguages: [String]? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> Locale {
        Locale(identifier: resolvePreferredLanguageCode(
            selectedLanguage: selectedLanguage,
            bundle: bundle,
            preferredLanguages: preferredLanguages,
            locale: locale
        ))
    }

    public static func string(
        _ key: String,
        bundle: Bundle = .main,
        value: String? = nil
    ) -> String {
        let localizedBundle = localizedBundle(for: bundle)
        return localizedBundle.localizedString(forKey: key, value: value ?? key, table: nil)
    }

    @discardableResult
    public static func syncPreferredLanguageCode(
        selectedLanguage: AppLanguageOption = selectedAppLanguage,
        bundle: Bundle = .main,
        preferredLanguages: [String]? = nil,
        userDefaults: UserDefaults = AppGroupUserDefaults.shared,
        locale: Locale = .autoupdatingCurrent
    ) -> Bool {
        let resolvedLanguage = resolvePreferredLanguageCode(
            selectedLanguage: selectedLanguage,
            bundle: bundle,
            preferredLanguages: preferredLanguages,
            locale: locale
        )
        let currentLanguage = userDefaults.string(forKey: AppStorageKeys.preferredLanguageCode)

        guard currentLanguage != resolvedLanguage else {
            return false
        }

        userDefaults.set(resolvedLanguage, forKey: AppStorageKeys.preferredLanguageCode)
        return true
    }

    private static func resolvePreferredLanguageCode(
        selectedLanguage: AppLanguageOption = selectedAppLanguage,
        bundle: Bundle = .main,
        preferredLanguages: [String]? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        if let selectedCode = selectedLanguage.languageCode {
            return selectedCode
        }

        if let preferredLanguage = preferredLanguages?.first,
           preferredLanguage.isEmpty == false {
            return preferredLanguage
        }

        if let bundleLanguage = bundle.preferredLocalizations.first,
           bundleLanguage.isEmpty == false {
            return bundleLanguage
        }

        if let preferredLanguage = Locale.preferredLanguages.first,
           preferredLanguage.isEmpty == false {
            return preferredLanguage
        }

        return locale.identifier
    }

    private static func localizedBundle(for bundle: Bundle) -> Bundle {
        let preferred = preferredLanguageCode
        let normalized = normalizedLanguageCode(from: preferred)

        let candidates = [preferred, normalized].filter { !$0.isEmpty }
        for candidate in candidates {
            if let path = bundle.path(forResource: candidate, ofType: "lproj"),
               let localizedBundle = Bundle(path: path) {
                return localizedBundle
            }
        }

        return bundle
    }

    private static func normalizedLanguageCode(from identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init) ?? identifier
    }
}

public enum AppDateFormatterFactory {
    public static func monthYearFormatter() -> DateFormatter {
        let formatter = baseFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter
    }

    public static func dayLabelFormatter() -> DateFormatter {
        let formatter = baseFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MEd")
        return formatter
    }

    public static func dateTimeFormatter() -> DateFormatter {
        let formatter = baseFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    public static func recordDetailDateFormatter() -> DateFormatter {
        let formatter = baseFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMMEEEEd")
        return formatter
    }

    public static func widgetMonthFormatter() -> DateFormatter {
        let formatter = baseFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }

    public static func fixedDayKeyFormatter(timeZone: TimeZone = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    public static func veryShortWeekdaySymbols() -> [String] {
        let formatter = baseFormatter()
        return formatter.veryShortStandaloneWeekdaySymbols
    }

    private static func baseFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = AppLocalization.locale
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }
}
