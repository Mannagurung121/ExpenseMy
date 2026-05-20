# OWASP Mobile Top 10 — Security Checklist for ExpenseMy

Last reviewed: 2026-05-19
App version: 0.1.0

---

## M1: Improper Credential Storage

**Status: REVIEW NEEDED**

**Risk:** Sensitive data stored in `UserDefaults` is readable by any process with the same bundle ID on a jailbroken device and is included in unencrypted iCloud/iTunes backups by default.

**What to check in ExpenseMy:**
- Search for `UserDefaults` usage across the codebase (`grep -r "UserDefaults" ExpenseMy/`).
- Confirm that any user-identifying data, API tokens (for future cloud sync), or sensitive configuration is stored in the Keychain instead.
- The Share Extension uses an App Group container (`UserDefaults(suiteName:)`) to pass transaction data — verify this container holds only transient parsing results, not long-lived sensitive values.

**Recommended action:**
- Audit every `UserDefaults` call and classify the stored value as sensitive or non-sensitive.
- Migrate any sensitive value to `SecItemAdd` / `Keychain` wrappers (e.g., `KeychainAccess` or a hand-rolled `KeychainHelper`).
- Mark the App Group `UserDefaults` container with `excludedFromBackup` where appropriate.

**Priority: HIGH**

---

## M2: Inadequate Supply Chain Security

**Status: LOW RISK**

**Risk:** Malicious or compromised third-party dependencies can introduce backdoors or vulnerabilities into the app.

**What to check in ExpenseMy:**
- The project currently has **no third-party Swift Package Manager dependencies**, which minimises supply chain attack surface.
- The only external tooling is SwiftLint (dev-only, not shipped in the app binary).

**Recommended action:**
- When adding any SPM dependency: pin to an exact version in `Package.resolved`, review the package's source and recent commit history, and check it against [osv.dev](https://osv.dev).
- The `security-scan.yml` CI workflow will automatically list all pinned dependencies on every PR for review.
- Prefer Apple first-party frameworks over third-party alternatives where possible.

**Priority: LOW**

---

## M3: Insecure Authentication / Authorization

**Status: N/A**

**Risk:** Weak or missing auth allows unauthorized access to user data.

**What to check in ExpenseMy:**
- ExpenseMy is currently a **local-only app** with no server authentication, user accounts, or remote data access. This category does not apply in its current form.

**Recommended action:**
- When cloud sync is added, implement OAuth 2.0 / Sign in with Apple — never roll a custom auth scheme.
- Enforce token expiry and secure token storage in the Keychain (see M1).
- Document auth requirements in this checklist before any networking feature is merged.

**Priority: N/A (revisit when cloud sync is planned)**

---

## M4: Insufficient Input Validation

**Status: REVIEW NEEDED**

**Risk:** Malformed or adversarially crafted input can cause crashes, incorrect data storage, or (in extreme cases) code injection.

**What to check in ExpenseMy:**
- `SmsParser.swift` — the core regex patterns that parse SMS text. Verify that:
  - Regex patterns are anchored and do not exhibit catastrophic backtracking (ReDoS).
  - Amounts and dates parsed from SMS are validated before being written to SwiftData (non-negative amounts, valid date ranges).
  - Unexpected SMS formats produce a graceful failure (e.g., `nil` return) rather than a crash.
- `AddTransactionView.swift` — manual entry fields. Verify amount fields reject non-numeric input, and merchant/note fields have a reasonable length cap.

**Recommended action:**
- Add unit tests in `ExpenseMyTests` for malformed SMS inputs (empty string, special characters, extremely long strings, Unicode edge cases).
- Replace any unbounded `.*` regex quantifiers with bounded alternatives (e.g., `.{1,20}`).
- Use `NumberFormatter` for amount parsing rather than direct `Double(string)` conversion.

**Priority: HIGH**

---

## M5: Insecure Communication

**Status: N/A (current) — PLANNING REQUIRED (future)**

**Risk:** Unencrypted or improperly verified network traffic exposes user financial data to interception.

**What to check in ExpenseMy:**
- The app currently makes **no network calls**. App Transport Security (ATS) is enforced at its default strict level, which is correct.
- No `NSAppTransportSecurity` exceptions exist in `Info.plist` — confirm this remains true.

**Recommended action (for future cloud sync):**
- Do not add any ATS exceptions (`NSAllowsArbitraryLoads`, `NSExceptionAllowsInsecureHTTPLoads`).
- Require TLS 1.2 minimum; prefer TLS 1.3.
- Implement certificate pinning for all ExpenseMy-controlled backend endpoints (see `docs/app-transport-security.md`).
- Use `URLSession` with a custom delegate for pinning; do not rely on ATS alone.

**Priority: N/A now — HIGH when any networking is added**

---

## M6: Inadequate Privacy Controls

**Status: REVIEW NEEDED**

**Risk:** Financial SMS data is among the most sensitive personal information on a device. Improper handling can expose it to other apps, backups, or logs.

**What to check in ExpenseMy:**
- Confirm that SMS content is never written to `NSLog` / `print` in production builds — Xcode logs are readable by connected Macs.
- Verify the SwiftData store (`ExpenseMy.store`) is stored in the app's sandboxed `Application Support` directory, not a shared location.
- The Share Extension App Group container is writable by any app that declares the same group — confirm only `group.com.expensemy.*` is declared and the group ID is not guessable.
- Review the Privacy Nutrition Label in App Store Connect to ensure it accurately reflects SMS data collection once the app is submitted.

**Recommended action:**
- Use `#if DEBUG` guards around any debug logging that touches SMS content or transaction amounts.
- Set `isExcludedFromBackup = true` on the SwiftData store URL if backup of financial history is undesirable.
- Confirm the App Group container is cleared after the Share Extension finishes parsing (transient data only).

**Priority: HIGH**

---

## M7: Insufficient Binary Protections

**Status: DOCUMENTATION**

**Risk:** Unprotected binaries can be reverse-engineered, patched, or re-signed by attackers.

**What to check in ExpenseMy:**
- **Code signing:** Confirm the app is signed with a valid Apple Distribution certificate for App Store submissions. Development builds should use a personal team certificate.
- **Bitcode:** Bitcode is deprecated as of Xcode 14. Ensure `ENABLE_BITCODE = NO` in Build Settings (Xcode default).
- **Stack canaries and PIE:** Enabled by default by the Swift compiler — no action required.
- **Entitlements:** Review `ExpenseMy.entitlements` and `ExpenseMyShare.entitlements` — remove any entitlements not actively used.

**Recommended action:**
- Before App Store submission, run `codesign --verify --deep --strict ExpenseMy.app`.
- Ensure `Release` builds have Swift optimization set to `Optimize for Speed [-O]` or `Optimize for Size [-Osize]` — this also makes reverse engineering harder.
- Do not ship the `.dSYM` bundle in the app archive; upload it separately to Crashlytics / Apple Crash Reporter.

**Priority: MEDIUM**

---

## M8: Security Misconfiguration

**Status: DOCUMENTATION**

**Risk:** Overly broad entitlements or misconfigured capabilities expand the attack surface.

**What to check in ExpenseMy:**
- `ExpenseMy.entitlements` — confirm only `com.apple.security.application-groups` (App Groups) is listed. Remove any unused entitlements.
- `ExpenseMyShare.entitlements` — same App Group should be listed; no additional entitlements needed.
- In Xcode, under Signing & Capabilities, verify no unused capabilities are toggled on (e.g., Push Notifications, iCloud, HealthKit).
- Confirm the App Group identifier follows reverse-DNS naming (`group.com.yourteam.expensemy`) and is not shared with unrelated apps.

**Recommended action:**
- Perform an entitlements audit before every App Store release: `codesign -d --entitlements - ExpenseMy.app`.
- Document each entitlement and its purpose in a comment in the `.entitlements` file.

**Priority: MEDIUM**

---

## M9: Insecure Data Storage

**Status: REVIEW NEEDED**

**Risk:** SwiftData (SQLite) stores data unencrypted by default. A device without a passcode or a compromised backup exposes all transaction data.

**What to check in ExpenseMy:**
- SwiftData uses SQLite under the hood. By default, the `.store` file is **not encrypted** at the application layer (it relies on iOS Data Protection).
- Confirm the SwiftData container directory has the correct iOS Data Protection class. Files created in `Application Support` receive `NSFileProtectionCompleteUntilFirstUserAuthentication` by default — consider upgrading to `NSFileProtectionComplete` for at-rest encryption when the device is locked.
- Verify no sensitive transaction fields are stored in plaintext in `UserDefaults` as a caching layer.

**Recommended action:**
- Set the SwiftData store URL's resource value: `url.setResourceValues({ $0.fileProtection = .complete })` — this ensures the SQLite file is encrypted when the device is locked.
- Add a test that verifies the store file is inaccessible when the device is locked (manual verification on a real device).
- For highly sensitive fields (e.g., full account numbers if ever stored), consider column-level encryption before writing to SwiftData.

**Priority: HIGH**

---

## M10: Insufficient Cryptography

**Status: N/A (current) — PLANNING REQUIRED (future)**

**Risk:** Weak, home-grown, or improperly used cryptography fails to protect data confidentiality and integrity.

**What to check in ExpenseMy:**
- The app currently performs **no cryptographic operations**. This category does not apply in its current form.

**Recommended action (for future cloud sync):**
- Use Apple's `CryptoKit` framework exclusively — never implement cryptographic primitives manually.
- For symmetric encryption: use `AES.GCM` (authenticated encryption).
- For key derivation: use `HKDF` or `PBKDF2` (via `CryptoKit`).
- For end-to-end encryption between devices: use `Curve25519` key exchange + `ChaChaPoly`.
- Never store encryption keys alongside the data they protect.
- Document the encryption scheme in this checklist before any crypto feature is merged.

**Priority: N/A now — HIGH when cloud sync is implemented**
