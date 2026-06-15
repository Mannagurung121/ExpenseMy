import Foundation

// CrashlyticsService wraps Firebase Crashlytics to centralise crash reporting.
// Call configure() once in AppDelegate/App init AFTER FirebaseApp.configure().
// All other methods are safe to call from any thread at any time.
//
// Without the Firebase SDK the stub implementations log to the console so that
// development builds still surface the same callsites without crashing.

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics

enum CrashlyticsService {

    // Call once at app launch, after FirebaseApp.configure().
    static func configure() {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }

    // Appends a line to the rolling log that is sent with the next crash report.
    // Use for breadcrumbs: key user actions, state transitions, feature flags.
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    // Records a non-fatal error so it appears in the Crashlytics dashboard
    // without ending the session. userInfo is merged into the crash metadata.
    static func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        if let userInfo {
            Crashlytics.crashlytics().record(error: error, userInfo: userInfo)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    // Associates subsequent events with this user identifier in the dashboard.
    // Pass an opaque ID, never PII such as an email address or full name.
    static func setUserID(_ id: String) {
        Crashlytics.crashlytics().setUserID(id)
    }

    // Attaches an arbitrary key-value pair to crash reports.
    // Useful for app state that doesn't fit neatly into userInfo (e.g. "theme", "locale").
    static func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}

#else

// Stub used when the FirebaseCrashlytics SDK is not linked (e.g. development
// builds or unit-test targets that don't include Firebase).
enum CrashlyticsService {

    static func configure() {
        print("[CrashlyticsService] configure() — Firebase SDK not linked, skipping.")
    }

    static func log(_ message: String) {
        print("[CrashlyticsService] log: \(message)")
    }

    static func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        print("[CrashlyticsService] recordError: \(error.localizedDescription), userInfo: \(userInfo ?? [:])")
    }

    static func setUserID(_ id: String) {
        print("[CrashlyticsService] setUserID: \(id)")
    }

    static func setCustomValue(_ value: Any, forKey key: String) {
        print("[CrashlyticsService] setCustomValue '\(value)' forKey '\(key)'")
    }
}

#endif
