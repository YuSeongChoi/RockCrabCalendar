import Foundation

public enum AppLocalization {
    public static var prefersEnglish: Bool {
        let preferred = Bundle.main.preferredLocalizations.first ?? Locale.autoupdatingCurrent.identifier
        return preferred.hasPrefix("en")
    }

    public static var showsKoreanHolidays: Bool {
        !prefersEnglish
    }

    public static func localized(ko: String, en: String) -> String {
        prefersEnglish ? en : ko
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
