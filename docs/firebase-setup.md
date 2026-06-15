# Firebase Setup Guide

This guide covers integrating Firebase Crashlytics, Analytics, and Remote Config into the ExpenseMy iOS app.

---

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** → enter a project name (e.g. `ExpenseMy-Production`).
3. Choose whether to enable Google Analytics (recommended — required for Remote Config audience targeting).
4. Click **Create project**.

---

## 2. Add the iOS App to Firebase

1. In the Firebase Console, click the **iOS** icon on the project overview page.
2. Enter the **Apple bundle ID** — this must exactly match the bundle identifier in `ExpenseMy.xcodeproj`:
   - Open Xcode → select the `ExpenseMy` target → **General** tab → **Bundle Identifier**.
   - Example: `com.yourname.ExpenseMy`
3. Enter an optional app nickname and App Store ID (can be added later).
4. Click **Register app**.

---

## 3. Download and Place GoogleService-Info.plist

1. Click **Download GoogleService-Info.plist** in the Firebase Console wizard.
2. In Xcode, drag the file into the **ExpenseMy** group (the one that contains `ExpenseMyApp.swift`).
   - In the dialog that appears, check **Copy items if needed**.
   - Ensure **Add to targets: ExpenseMy** is checked.
3. **Do NOT commit this file to git.** It is already listed in `.gitignore`:
   ```
   GoogleService-Info.plist
   ```
   If you accidentally staged it, remove it with:
   ```bash
   git rm --cached ExpenseMy/GoogleService-Info.plist
   ```
4. Each team member and CI environment must obtain their own copy from the Firebase Console or from the team's secure secrets store (see `docs/secrets-setup.md`).

---

## 4. Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the Firebase Apple SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Select **Up to Next Major Version** from the current release.
4. In the **Add to Target** step, select these packages for the `ExpenseMy` target:
   - `FirebaseCrashlytics`
   - `FirebaseAnalytics`
   - `FirebaseRemoteConfig`
5. Click **Add Package**.

> **Note:** The `#if canImport(Firebase*)` guards in the service files mean the app compiles and runs without the SDK linked. You can add the SDK at any time without changing the service files.

---

## 5. Initialize Firebase in the App Entry Point

Open `ExpenseMy/ExpenseMyApp.swift` and add the initialisation call:

```swift
import FirebaseCore   // add this import

@main
struct ExpenseMyApp: App {
    init() {
        FirebaseApp.configure()          // must be first
        CrashlyticsService.configure()
        RemoteConfigService.fetchAndActivate { _ in }
        AnalyticsService.trackAppLaunch()
    }
    // ...
}
```

---

## 6. Enable Crashlytics in Firebase Console

1. In the Firebase Console, navigate to **Crashlytics** (under the **Release & Monitor** section).
2. Click **Enable Crashlytics**.
3. Run the app on a device or simulator, then force a test crash:
   ```swift
   // Temporary — remove after confirming Crashlytics works
   fatalError("Test crash")
   ```
4. Re-launch the app. Within a few minutes the crash should appear in the Crashlytics dashboard.

---

## 7. Set Up Remote Config Default Values in Firebase Console

1. Navigate to **Remote Config** in the Firebase Console.
2. Click **Add parameter** for each of the following:

   | Parameter Key                   | Default Value | Data Type |
   |---------------------------------|---------------|-----------|
   | `is_ml_categorization_enabled`  | `false`       | Boolean   |
   | `is_budget_goals_enabled`       | `false`       | Boolean   |
   | `is_cloud_sync_enabled`         | `false`       | Boolean   |
   | `is_export_reports_enabled`     | `false`       | Boolean   |
   | `max_transactions_per_day`      | `100`         | Number    |

3. Click **Publish changes**.

These defaults in the console should match `RemoteConfigService.defaults` in code. If the SDK cannot reach Firebase the in-code defaults are used as a final fallback.

---

## 8. Verify the Integration

### Crashlytics
- Run the app on a **real device** (Crashlytics is limited in the simulator).
- Call `CrashlyticsService.log("integration test")` then force a non-fatal error with `CrashlyticsService.recordError(...)`.
- Check the **Crashlytics → Non-fatal** section in the console within 5 minutes.

### Analytics
- Enable **DebugView** in the Firebase Console (**Analytics → DebugView**).
- Launch the simulator with the `-FIRDebugEnabled` launch argument:
  - In Xcode: **Edit Scheme → Run → Arguments Passed on Launch → add `-FIRDebugEnabled`**.
- Perform tracked actions (add a transaction, view the dashboard).
- Events should appear in DebugView in real time.

### Remote Config
- In the Firebase Console, temporarily flip `is_budget_goals_enabled` to `true`.
- In a debug build `minimumFetchInterval` is 0, so a fresh fetch will pick up the change immediately.
- Call `RemoteConfigService.fetchAndActivate { success in print(success) }` and verify the property returns `true`.

---

## Security Notes

- `GoogleService-Info.plist` contains your Firebase project's API keys. These keys are **not** secret in the traditional sense (they identify the project, not grant admin access), but they should still be treated as semi-sensitive to prevent quota abuse.
- Restrict which iOS bundle IDs and IP addresses can use your Firebase API key in **Google Cloud Console → APIs & Services → Credentials**.
- For CI, inject `GoogleService-Info.plist` from a secrets manager at build time (see `docs/secrets-setup.md`).
