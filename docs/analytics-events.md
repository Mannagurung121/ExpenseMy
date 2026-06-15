# Analytics Events Reference

All events are tracked through `AnalyticsService` (`ExpenseMy/Services/AnalyticsService.swift`), which wraps Firebase Analytics. This document is the authoritative reference for every event in the app.

---

## Event Catalogue

| Event Name            | Firebase Event Key        | Parameters                                                                                   | Trigger Screen / Action                                 | Purpose                                                          |
|-----------------------|---------------------------|----------------------------------------------------------------------------------------------|---------------------------------------------------------|------------------------------------------------------------------|
| App Launch            | `app_open`                | _(none)_                                                                                     | App cold or warm launch                                 | Measures DAU/MAU and session starts                              |
| Transaction Added     | `transaction_added`       | `category: String`, `amount: Double`, `transaction_type: "credit"\|"debit"`                 | Transaction form — on successful save                   | Tracks which categories and transaction types are used most      |
| Dashboard Viewed      | `dashboard_viewed`        | _(none)_                                                                                     | Dashboard / Summary screen — `onAppear`                 | Measures how often users check their spending overview           |
| SMS Shared            | `sms_shared`              | _(none)_                                                                                     | Share sheet — SMS option selected                       | Tracks SMS sharing feature adoption                              |
| Filter Applied        | `filter_applied`          | `filter_type: String` (e.g. `"date_range"`, `"category"`, `"type"`)                         | Transaction list — filter picker changed                | Identifies which filters users rely on most                      |
| Widget Interaction    | `widget_interaction`      | `widget_type: String` (e.g. `"balance_summary"`, `"recent_transactions"`)                   | Home screen widget tapped                               | Measures widget engagement and helps prioritise widget roadmap   |
| App Error             | `app_error`               | `error_domain: String`, `error_code: Int`, `error_description: String`                      | Any screen where a surfaced error occurs                | Aggregates non-fatal errors for trend analysis alongside Crashlytics |

---

## Custom Dimensions and User Properties

Firebase Analytics supports custom user properties (dimensions applied to the user, not an individual event). The following are planned but not yet implemented:

| User Property              | Values                         | Purpose                                                  |
|----------------------------|--------------------------------|----------------------------------------------------------|
| `transaction_count_bucket` | `"0-10"`, `"11-50"`, `"51+"`  | Segment users by data volume for feature targeting       |
| `preferred_currency`       | ISO 4217 code (e.g. `"INR"`)  | Localisation analytics                                   |
| `onboarding_completed`     | `"true"` / `"false"`          | Funnel analysis                                          |

To set a user property once it is implemented:
```swift
// Firebase SDK example (add to AnalyticsService when ready)
Analytics.setUserProperty("51+", forName: "transaction_count_bucket")
```

---

## Viewing Events in Firebase Console

### Real-Time Debug (DebugView)
1. In Xcode: **Edit Scheme → Run → Arguments Passed on Launch → add `-FIRDebugEnabled`**.
2. In the Firebase Console: **Analytics → DebugView**.
3. Events appear within seconds of being triggered in the simulator or device.

### Historical Data (Events Dashboard)
- **Analytics → Events**: lists all event names, event counts, and user counts over the selected date range.
- Click any event name to see parameter breakdowns (e.g. which `category` values appear in `transaction_added`).
- Data appears with a 24–48 hour delay in the standard dashboard.

### Funnels
- **Analytics → Funnels → Create funnel**:
  - Example funnel: `app_open` → `dashboard_viewed` → `transaction_added`
  - This reveals where users drop off before adding their first transaction.

### Audiences
- **Analytics → Audiences**: create segments for use in Remote Config conditions.
  - Example: users who have triggered `transaction_added` more than 10 times in 30 days → target with `is_budget_goals_enabled = true`.

---

## Privacy Compliance

### What IS Collected
- **Interaction events**: which screens are viewed, which features are used, which filters are applied.
- **Aggregated amounts**: `amount` in `transaction_added` (used for cohort analysis of high-value vs low-value users).
- **Error metadata**: error domain and code strings (no stack traces — those go to Crashlytics).
- **Device metadata** (collected automatically by Firebase): iOS version, device model, app version, country (coarse, from IP), language.

### What is NOT Collected
- **Transaction descriptions or merchant names** — never logged.
- **Raw SMS content** — the SMS parser runs entirely on-device; no SMS text leaves the device.
- **Precise geolocation** — Firebase derives a coarse country from the IP address only.
- **Personally identifiable information (PII)** — no names, emails, phone numbers, or national IDs are sent to Analytics.
- **Financial account numbers** — never stored or transmitted.

### GDPR / Privacy Considerations

| Requirement                     | Implementation                                                                                        |
|---------------------------------|-------------------------------------------------------------------------------------------------------|
| Lawful basis                    | Legitimate interest (app improvement) for aggregate analytics; no personal profiling                  |
| Data minimisation               | No PII in any event parameter; amounts are numeric with no identifying context                        |
| Right to erasure                | Firebase Analytics data is automatically purged after the project-level retention period (default 14 months); users can reset their Analytics identifier in iOS Settings → Privacy → Apple Advertising |
| Data residency                  | Set in Firebase Console → Project Settings → Google Analytics → Data residency                        |
| App Privacy nutrition label     | Declare "Analytics Data" → "Product Interaction" under "Data Used to Track You" if advertising features are enabled; otherwise declare under "Data Not Linked to You" |
| Children (COPPA / GDPR-K)       | If the app ever targets under-13 users, disable analytics collection entirely for those sessions: `Analytics.setAnalyticsCollectionEnabled(false)` |

> **Audit note:** Before launching in the EU, confirm with legal that the Firebase Analytics data processing agreement (DPA) is signed via the Google Cloud Console.
