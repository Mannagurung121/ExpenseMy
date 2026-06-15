# Secure Storage Architecture Guide

This document describes how ExpenseMy stores data, why each storage mechanism was chosen, and how to classify new data correctly.

---

## Storage Layer Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYERS                             │
├────────────────────────┬────────────────────────┬───────────────────┤
│     UserDefaults       │      Keychain           │    SwiftData      │
│  (Non-Sensitive Only)  │  (Sensitive / Secrets)  │ (Transaction Data)│
├────────────────────────┼────────────────────────┼───────────────────┤
│ • Plaintext plist      │ • AES-256 encrypted     │ • SQLite on-disk  │
│ • Included in iCloud   │ • Hardware-backed on    │ • App sandbox     │
│   and iTunes backups   │   Secure Enclave devices│   protected       │
│ • Sandbox-protected    │ • Excluded from backups │ • Not encrypted   │
│   (no encryption)      │ • Requires device unlock│   by default      │
│                        │   to access             │                   │
├────────────────────────┼────────────────────────┼───────────────────┤
│ SecureStorageService   │ SecureStorageService    │ SwiftData models  │
│ .storeUserPreference() │ .storeSensitiveData()   │ in Models/        │
│ .getUserPreference()   │ .getSensitiveData()     │                   │
│                        │ KeychainService (direct)│                   │
└────────────────────────┴────────────────────────┴───────────────────┘
```

All storage access should go through `SecureStorageService` (for preferences and secrets) or the SwiftData model layer (for transaction records). Callers should not import `Security` or interact with `KeychainService` directly.

---

## When to Use Each Storage Mechanism

### UserDefaults — for non-sensitive UI preferences

Use when:
- The data is a user interface preference (theme, language, last selected tab).
- Losing the data on device restore would be mildly inconvenient at worst.
- The data contains no personal identifiers, credentials, or financial figures.

Do NOT use for:
- Auth tokens, session cookies, refresh tokens.
- User IDs that could be correlated with external systems.
- Any data whose exposure in a plaintext backup would be a privacy or security issue.

**Examples:**
```swift
SecureStorageService.storeUserPreference(key: StorageKey.preferredTheme, value: "dark")
SecureStorageService.getUserPreference(key: StorageKey.lastSelectedFilter)
SecureStorageService.setOnboardingCompleted()
```

### Keychain — for sensitive credentials and secrets

Use when:
- The data is a token, key, password, or user identifier.
- You need hardware-backed encryption (Secure Enclave on A-series chips).
- The data must not appear in device backups (compliance or regulatory requirement).
- The data must only be readable when the device is unlocked.

**Examples:**
```swift
SecureStorageService.storeSensitiveData(key: StorageKey.authToken, data: tokenData)
SecureStorageService.getSensitiveData(key: StorageKey.authToken)
SecureStorageService.clearAllSensitiveData()   // call on sign-out
```

### SwiftData — for structured transaction records

Use when:
- Data is a domain model (Transaction, Category, Budget) that needs querying and relationships.
- You need sorted/filtered reads, relationships between records, or migration support.
- The data volume is too large or structured for a key-value store.

Note: SwiftData's SQLite store is **not** encrypted by default. Do not store auth material or cryptographic keys here. Transaction amounts and categories are stored here because they are app-functional data protected by the iOS app sandbox (not accessible to other apps), which is acceptable for a personal finance app that does not operate under PCI-DSS or similar regulated frameworks.

---

## Data Classification Table

| Data                        | Classification  | Storage        | Rationale                                                          |
|-----------------------------|-----------------|----------------|--------------------------------------------------------------------|
| Auth / session token        | Secret          | Keychain       | Must survive app updates; must not appear in backups               |
| Refresh token               | Secret          | Keychain       | Long-lived credential; hardware protection required                 |
| User ID (opaque)            | Sensitive       | Keychain       | Can be correlated with backend; not suitable for plaintext backup   |
| UI theme preference         | Non-sensitive   | UserDefaults   | No security impact; acceptable to lose on restore                   |
| Last selected filter        | Non-sensitive   | UserDefaults   | Convenience state only                                              |
| Onboarding completed flag   | Non-sensitive   | UserDefaults   | Loss means user sees onboarding again — acceptable                  |
| Transaction amount          | Functional      | SwiftData      | App-functional; sandbox-protected; not a secret                     |
| Transaction category        | Functional      | SwiftData      | App-functional; sandbox-protected                                   |
| Transaction description     | Functional      | SwiftData      | May contain merchant names; app-sandbox protection is sufficient    |
| SMS message content         | Transient       | Never persisted| Parsed in-memory and discarded; raw SMS never written to disk       |
| Cryptographic keys (future) | Secret          | Keychain / SE  | Must use Secure Enclave APIs (`SecKeyCreateRandomKey`) when added   |

---

## Keychain Security Properties

### Encryption
- Keychain items are encrypted using **AES-256** in GCM mode.
- The encryption key is derived from the device passcode and is unique per device.
- Changing or removing the device passcode re-encrypts all Keychain data.

### Secure Enclave
- On all Apple devices since iPhone 5s, the Secure Enclave Processor (SEP) is a dedicated hardware security module.
- Private keys generated with `kSecAttrTokenIDSecureEnclave` never leave the SEP — even the OS cannot read them.
- Keychain metadata (item existence) may be stored in the application processor, but the actual secret bytes are SEP-resident when using SE-backed keys.

### Accessibility Level
ExpenseMy uses **`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`** for all Keychain items. This means:
- Items are readable only while the device is unlocked (Face ID / Touch ID / passcode).
- Items are **not** transferred to a new device via iCloud Keychain or iTunes backup.
- Background tasks that run while the device is locked (e.g. background fetch) cannot read these items — this is intentional and acceptable for a user-interactive app.

If a future feature requires reading a token from a background extension (e.g. a widget timeline provider), switch to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` only for those specific items and document the reason.

### Sharing Between App and Extensions
The app currently has no shared app group. If a Widget Extension or Share Extension needs Keychain access in the future:
1. Enable the **Keychain Sharing** capability in the `ExpenseMy` target.
2. Add a `kSecAttrAccessGroup` attribute to the Keychain query in `KeychainService`.
3. Both the host app and the extension must declare the same keychain group in their entitlements.

---

## Migration: Moving Sensitive Data from UserDefaults to Keychain

If any prior version of the app stored sensitive values (e.g. a user ID) in UserDefaults, follow these steps to migrate on upgrade:

```swift
// AppMigrationService.swift (example — create if needed)
static func migrateUserDefaultsToKeychain() {
    let legacyKey = "legacy_user_id"   // old UserDefaults key
    guard let legacyValue = UserDefaults.standard.string(forKey: legacyKey) else {
        return   // already migrated or never existed
    }

    // Write to Keychain first, then remove from UserDefaults
    let migrated = SecureStorageService.storeUserPreference is not right here —
    // use storeSensitiveData for sensitive values:
    guard let data = legacyValue.data(using: .utf8) else { return }
    SecureStorageService.storeSensitiveData(key: StorageKey.userID, data: data)
    UserDefaults.standard.removeObject(forKey: legacyKey)
}
```

Call this migration exactly once per install by gating it on a `UserDefaults` migration version flag. Never delete the UserDefaults value before confirming the Keychain write succeeded.

---

## OWASP M9 — Insecure Data Storage Compliance

[OWASP Mobile Top 10 — M9](https://owasp.org/www-project-mobile-top-10/) covers insecure storage of sensitive data. The following table maps each control to the ExpenseMy implementation.

| OWASP M9 Control                                         | ExpenseMy Control                                                                            | Status     |
|----------------------------------------------------------|----------------------------------------------------------------------------------------------|------------|
| Do not store credentials in plaintext                    | Auth tokens stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`           | ✅ Compliant |
| Do not store sensitive data in UserDefaults              | `SecureStorageService` enforces the boundary; `StorageKey` enum prevents accidental misuse   | ✅ Compliant |
| Exclude sensitive files from backups                     | Keychain items with `ThisDeviceOnly` are not included in any backup                          | ✅ Compliant |
| Encrypt data at rest                                     | Keychain provides AES-256; SwiftData uses SQLite (sandbox-only; acceptable for this use case)| ⚠️ Partial — enable SQLite encryption if regulated data is added |
| Do not log sensitive data                                | `CrashlyticsService` and `AnalyticsService` exclude PII; SMS content is never persisted      | ✅ Compliant |
| Remove sensitive data on sign-out                        | `SecureStorageService.clearAllSensitiveData()` deletes all Keychain items on sign-out        | ✅ Compliant |
| Protect the Keychain with access control (biometrics)   | Not yet implemented — consider `SecAccessControlCreateWithFlags(.biometryAny)` for high-risk items | 🔲 Future  |

> **See also:** `docs/security-checklist.md` for the full security posture and `docs/secrets-setup.md` for CI credential handling.
