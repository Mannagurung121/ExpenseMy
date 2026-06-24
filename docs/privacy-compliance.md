# Privacy & Compliance Guide — ExpenseMy

This document explains Apple's Privacy Manifest requirements, what ExpenseMy
declares today, the GDPR/CCPA posture of a local-only financial app, the
changes required before App Store submission, and how to audit the privacy
declarations using Xcode's privacy report generator.

It is the companion to the manifest file at
[`ExpenseMy/PrivacyInfo.xcprivacy`](../ExpenseMy/PrivacyInfo.xcprivacy).

---

## 1. Apple's Privacy Manifest — what it is and why it is required

A **Privacy Manifest** (`PrivacyInfo.xcprivacy`) is a property-list file bundled
with the app that declares its privacy practices in a machine-readable format.
Xcode merges the app's manifest with the manifest of every linked SDK to
produce an aggregate **Privacy Report**.

Since **1 May 2024**, the App Store rejects submissions that:

1. Use a **required-reason API** (see §4) without declaring an approved reason, or
2. Link a **commonly used third-party SDK** that ships without its own manifest
   and signature.

The manifest also feeds the **Privacy Nutrition Label** shown on the product
page in the App Store. The tooling that reads and enforces the manifest is
baselined on **iOS 17 / Xcode 15+**.

A manifest declares four things:

| Key | Meaning |
|---|---|
| `NSPrivacyTracking` | Whether the app tracks users (ATT sense). |
| `NSPrivacyTrackingDomains` | Domains used for tracking (must be empty if not tracking). |
| `NSPrivacyCollectedDataTypes` | Categories of data collected (transmitted off device). |
| `NSPrivacyAccessedAPITypes` | Required-reason APIs used, each with an approved reason code. |

---

## 2. What ExpenseMy declares

ExpenseMy is a **local-only** app: bank-SMS transactions are parsed on device,
stored in SwiftData on device, and never transmitted. Firebase
(Crashlytics / Analytics / Remote Config) is **conditionally compiled** and is a
no-op stub unless the SDK is linked and a real `GoogleService-Info.plist` is
present. The manifest reflects that reality.

### Tracking

| Field | Value | Rationale |
|---|---|---|
| `NSPrivacyTracking` | `false` | No cross-app/website data linking, no data brokers, no IDFA. |
| `NSPrivacyTrackingDomains` | empty | Required to be empty when tracking is `false`; the app makes no network calls. |

### Collected data types

> **Important nuance.** Apple defines *collection* as transmitting data off the
> device in a form linkable to the user or device. Because ExpenseMy keeps all
> data on device, it strictly has **nothing to declare** here, and an empty
> array would be accepted. We document the data types the app *handles* so the
> manifest is audit-ready the moment off-device transmission is enabled.

| Data type | Manifest identifier | Linked | Tracking | Purpose | Notes |
|---|---|---|---|---|---|
| Transaction data (amount, merchant, bank, category) | `NSPrivacyCollectedDataTypeOtherFinancialInfo` | `true` | `false` | App Functionality | On-device only today. The user's own financial history. |
| Usage / interaction (screen views, taps) | `NSPrivacyCollectedDataTypeProductInteraction` | `false` | `false` | Analytics | Only emitted when Firebase Analytics is actually linked. |

### Accessed (required-reason) APIs

| API category | Manifest identifier | Reason code | Why |
|---|---|---|---|
| User Defaults | `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | First-party preferences (theme, filter, onboarding flag) read back only by this app and its app-group extension. |
| File timestamp | `NSPrivacyAccessedAPICategoryFileTimestamp` | `DDA9.1` | SwiftData/Foundation read timestamps of the store inside the app's own container. |

---

## 3. GDPR / CCPA considerations

ExpenseMy's local-only architecture is its strongest privacy control: there is
no server, no account, and no PII transmission, which removes most controller
obligations under GDPR/CCPA.

- **Data minimisation (GDPR Art. 5(1)(c)).** Only the fields needed to display
  spending are parsed from SMS. Raw SMS bodies are treated as transient.
- **Storage limitation & user control.** Because data lives on device, deletion
  is achieved by deleting a transaction or uninstalling the app — no
  server-side erasure request (GDPR Art. 17) is needed while the app is
  local-only.
- **No sale/sharing of personal information (CCPA/CPRA).** ExpenseMy does not
  sell or share data; there is nothing to opt out of.
- **No PII transmitted unless Firebase is enabled.** With Firebase Analytics
  on, only de-identified product-interaction events (no transaction amounts,
  no merchant names) are sent. With Crashlytics on, set only an opaque user ID
  — never an email or name (the `CrashlyticsService` doc comment already warns
  this).
- **Sensitive category.** Financial data is sensitive; treat it accordingly in
  logs (see `LoggingService.redact`) and never `print` amounts/SMS bodies in
  release builds (OWASP M6 in `docs/security-checklist.md`).

### What changes when cloud sync / Firebase is enabled

Before turning on any off-device transmission:

1. Re-confirm the **collected data types** above are accurate and remove the
   "device only" caveat for any type now transmitted.
2. Add `NSPrivacyTrackingDomains` entries **only** if any domain performs
   tracking (it should not — keep `NSPrivacyTracking` false).
3. Complete the **App Privacy** questionnaire in App Store Connect so the
   Nutrition Label matches the manifest.
4. Add a **Data Processing Agreement** with Google (Firebase) and update the
   privacy policy URL.
5. Surface an **in-app analytics opt-out** if targeting EU users, and gate
   `AnalyticsService` calls on that consent.

---

## 4. Required-reason APIs — reference

Apple publishes a fixed list of API categories and the only acceptable reason
codes for each. The two ExpenseMy uses:

- **User Defaults — `CA92.1`:** "Access information from the same app, per its
  documentation." Correct for first-party preferences not shared with other
  developers' code.
- **File timestamp — `DDA9.1`:** "Access the timestamps of files inside the
  app's container, app group container, or CloudKit container." Correct for the
  sandboxed SwiftData store.

If a future dependency or feature uses another required-reason category (e.g.
**System boot time** `35F9.1`, **Disk space** `E174.1`, **Active keyboard**),
add a matching entry with an approved reason before submission.

---

## 5. Changes needed before App Store submission

- [ ] Confirm `PrivacyInfo.xcprivacy` is a member of the **ExpenseMy** target
      and is copied into the bundle (it appears under "Copy Bundle Resources").
- [ ] If the Share Extension begins using a required-reason API, add a separate
      manifest to the **ExpenseMyShare** target.
- [ ] Verify every linked third-party SDK ships its own signed manifest
      (Firebase iOS SDK does, as of recent versions).
- [ ] Fill in the **App Privacy** details in App Store Connect so they match
      this manifest and the Nutrition Label.
- [ ] Provide a privacy policy URL (required for any app that handles personal
      data, even on-device financial data).
- [ ] Re-run the privacy audit (§6) and resolve any discrepancies.

---

## 6. Auditing privacy declarations with Xcode

Xcode generates an aggregate **Privacy Report** from the app's manifest plus all
linked SDK manifests.

### Generate the report from an archive (GUI)

1. **Product → Archive** to build a release archive.
2. In the **Organizer**, right-click the archive → **Generate Privacy Report**.
3. Xcode produces a PDF aggregating: collected data types, tracking status, and
   every required-reason API across the app and its SDKs.
4. Compare the PDF against §2 of this document and against the App Store Connect
   questionnaire — they must agree.

### Inspect SDK manifests on the command line

```bash
# Find every privacy manifest bundled in the built .app (app + SDKs)
find "ExpenseMy.app" -name "PrivacyInfo.xcprivacy"

# Pretty-print the app's own manifest to verify the keys
plutil -p ExpenseMy/PrivacyInfo.xcprivacy

# Validate the plist is well-formed (CI-friendly; non-zero exit on error)
plutil -lint ExpenseMy/PrivacyInfo.xcprivacy
```

### Verify required-reason API usage

If a submission is rejected for an undeclared required-reason API, Apple names
the API category in the rejection. Map it to the published reason-code list, add
the entry to `NSPrivacyAccessedAPITypes`, regenerate the report, and resubmit.

> Tip: add `plutil -lint ExpenseMy/PrivacyInfo.xcprivacy` to CI so a malformed
> manifest fails fast rather than at submission time.
