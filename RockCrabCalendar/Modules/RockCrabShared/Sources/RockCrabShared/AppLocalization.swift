import Foundation

public enum AppLocalization {
    public static var locale: Locale {
        Locale(identifier: preferredLanguageCode)
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

    @discardableResult
    public static func syncPreferredLanguageCode(
        bundle: Bundle = .main,
        preferredLanguages: [String]? = nil,
        userDefaults: UserDefaults = AppGroupUserDefaults.shared,
        locale: Locale = .autoupdatingCurrent
    ) -> Bool {
        let resolvedLanguage = resolvePreferredLanguageCode(
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
        bundle: Bundle = .main,
        preferredLanguages: [String]? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
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
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }
}
