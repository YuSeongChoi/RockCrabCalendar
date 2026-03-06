import Foundation

public enum AppGroupUserDefaults {
    public static let suiteName = "group.ys.RockCrabCalendar"
    private static let migrationFlagKey = "didMigrateSharedUserDefaultsToAppGroup"

    public static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public static func migrateFromStandardIfNeeded(
        keys: [String],
        standard: UserDefaults = .standard,
        target: UserDefaults = AppGroupUserDefaults.shared
    ) {
        guard target.object(forKey: migrationFlagKey) == nil else { return }

        for key in keys {
            guard target.object(forKey: key) == nil else { continue }
            guard let value = standard.object(forKey: key) else { continue }
            target.set(value, forKey: key)
        }

        target.set(true, forKey: migrationFlagKey)
    }
}
