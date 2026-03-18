import Foundation

public enum AppLanguageOption: String, CaseIterable, Codable, Identifiable {
    case system
    case korean
    case english

    public var id: String { rawValue }

    public var languageCode: String? {
        switch self {
        case .system:
            return nil
        case .korean:
            return "ko"
        case .english:
            return "en"
        }
    }

    public var titleKey: String {
        switch self {
        case .system:
            return "시스템 설정 사용"
        case .korean:
            return "한국어"
        case .english:
            return "English"
        }
    }

    public var displayName: String {
        AppLocalization.string(titleKey)
    }
}
