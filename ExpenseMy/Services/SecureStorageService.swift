import Foundation

// SecureStorageService is the single entry point for all persistent storage
// in the app. It enforces a clear security boundary:
//
//   • SENSITIVE data (tokens, user IDs, credentials) → KeychainService
//     Encrypted at rest, hardware-backed, excluded from backups.
//
//   • NON-SENSITIVE preferences (UI theme, last filter selection) → UserDefaults
//     Convenient key-value store; stored as plaintext, included in backups.
//     Never put anything here that would cause harm if a backup were leaked.
//
//   • TRANSACTION RECORDS → SwiftData (see Models/)
//     Structured relational store; app-sandbox protected but not encrypted.
//     Suitable for financial records; DO NOT store auth material here.
//
// Callers should always use StorageKey constants rather than raw strings to
// prevent key collisions and make refactoring safe.

enum StorageKey {
    // Keychain keys — sensitive data
    static let userID = "user_id"
    static let authToken = "auth_token"
    static let refreshToken = "refresh_token"

    // UserDefaults keys — non-sensitive UI preferences
    static let preferredTheme = "preferred_theme"
    static let lastSelectedFilter = "last_selected_filter"
    static let onboardingCompleted = "onboarding_completed"
    static let lastDashboardTab = "last_dashboard_tab"
}

enum SecureStorageService {

    // MARK: - Sensitive Data (Keychain)

    // Stores arbitrary binary data in the Keychain. Use for raw credentials,
    // cryptographic keys, or opaque tokens returned by an auth server.
    static func storeSensitiveData(key: String, data: Data) {
        let success = KeychainService.save(key: key, data: data)
        #if DEBUG
        if !success {
            print("[SecureStorageService] storeSensitiveData failed for key '\(key)'")
        }
        #endif
    }

    // Retrieves binary data from the Keychain. Returns nil if the item has
    // never been stored or was deleted (e.g. after device restore or app uninstall).
    static func getSensitiveData(key: String) -> Data? {
        KeychainService.load(key: key)
    }

    // Deletes every known Keychain item managed by this service.
    // Call on sign-out to ensure credentials do not outlive a user session.
    static func clearAllSensitiveData() {
        let keychainKeys = [
            StorageKey.userID,
            StorageKey.authToken,
            StorageKey.refreshToken
        ]
        keychainKeys.forEach { KeychainService.delete(key: $0) }
    }

    // MARK: - User Preferences (UserDefaults — non-sensitive only)

    // Persists a UI or behaviour preference. Never store tokens, passwords,
    // or anything personally identifying here — use storeSensitiveData instead.
    static func storeUserPreference(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    // Retrieves a previously stored preference string. Returns nil if unset.
    static func getUserPreference(key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    // MARK: - Onboarding State

    // Returns true only after setOnboardingCompleted() has been called.
    // Stored in UserDefaults because its loss on device-restore is acceptable
    // (the user simply sees the onboarding flow again, which is harmless).
    static func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: StorageKey.onboardingCompleted)
    }

    // Marks onboarding as completed. Call at the final step of the onboarding flow.
    static func setOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: StorageKey.onboardingCompleted)
    }
}
