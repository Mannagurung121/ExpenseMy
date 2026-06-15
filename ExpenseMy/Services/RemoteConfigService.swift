import Foundation

// RemoteConfigService wraps Firebase Remote Config and exposes feature flags
// as typed computed properties. Defaults are intentionally conservative (false /
// minimum values) so that a failed fetch never enables an unstable feature.
//
// Call fetchAndActivate() early in the app lifecycle (e.g. after scene phase
// becomes .active) to pull the latest values from the console. The activated
// values persist on-device and are read synchronously via the computed properties.

#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig

enum RemoteConfigService {

    // Safe defaults applied before the first successful fetch.
    // Mirror these in the Firebase Console under Remote Config → Defaults.
    private static let defaults: [String: NSObject] = [
        "is_ml_categorization_enabled": false as NSObject,
        "is_budget_goals_enabled": false as NSObject,
        "is_cloud_sync_enabled": false as NSObject,
        "is_export_reports_enabled": false as NSObject,
        "max_transactions_per_day": 100 as NSObject
    ]

    // Enables on-device ML model for automatic transaction categorisation.
    static var isMLCategorizationEnabled: Bool {
        RemoteConfig.remoteConfig().configValue(forKey: "is_ml_categorization_enabled").boolValue
    }

    // Enables the budget goals / spending-limit feature.
    static var isBudgetGoalsEnabled: Bool {
        RemoteConfig.remoteConfig().configValue(forKey: "is_budget_goals_enabled").boolValue
    }

    // Gate for iCloud / Firebase cloud sync (planned future feature).
    static var isCloudSyncEnabled: Bool {
        RemoteConfig.remoteConfig().configValue(forKey: "is_cloud_sync_enabled").boolValue
    }

    // Enables CSV / PDF export reports feature.
    static var isExportReportsEnabled: Bool {
        RemoteConfig.remoteConfig().configValue(forKey: "is_export_reports_enabled").boolValue
    }

    // Hard cap on transactions the user can add per day.
    // Reducing this remotely provides a circuit-breaker if a parser bug
    // causes runaway inserts.
    static var maxTransactionsPerDay: Int {
        Int(RemoteConfig.remoteConfig().configValue(forKey: "max_transactions_per_day").numberValue)
    }

    // Fetches values from Firebase and activates them for the current session.
    // completion(true)  — new values were fetched and activated successfully.
    // completion(false) — fetch failed; previously cached / default values remain active.
    static func fetchAndActivate(completion: @escaping (Bool) -> Void) {
        let rc = RemoteConfig.remoteConfig()
        rc.setDefaults(defaults)

        let settings = RemoteConfigSettings()
        // 1-hour minimum fetch interval in production; set to 0 for debug builds.
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        rc.configSettings = settings

        rc.fetchAndActivate { status, error in
            if let error {
                print("[RemoteConfigService] fetchAndActivate error: \(error.localizedDescription)")
                completion(false)
                return
            }
            let succeeded = status == .successFetchedFromRemote || status == .successUsingPreFetchedData
            completion(succeeded)
        }
    }
}

#else

// Stub used when the FirebaseRemoteConfig SDK is not linked.
enum RemoteConfigService {

    static var isMLCategorizationEnabled: Bool { false }
    static var isBudgetGoalsEnabled: Bool { false }
    static var isCloudSyncEnabled: Bool { false }
    static var isExportReportsEnabled: Bool { false }
    static var maxTransactionsPerDay: Int { 100 }

    static func fetchAndActivate(completion: @escaping (Bool) -> Void) {
        print("[RemoteConfigService] fetchAndActivate — Firebase SDK not linked, returning defaults.")
        completion(false)
    }
}

#endif
