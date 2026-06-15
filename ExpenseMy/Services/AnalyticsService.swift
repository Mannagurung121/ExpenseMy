import Foundation

// AnalyticsService wraps Firebase Analytics and provides strongly-typed,
// app-specific tracking methods. Callers never reference Firebase event names
// directly, which makes refactoring and A/B testing safer.
//
// Without the Firebase SDK the stub implementations print to the console so
// development builds still surface the same callsites without crashing.

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics

enum AnalyticsService {

    // Logged at app startup after the first SwiftUI view appears.
    static func trackAppLaunch() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    // Logged whenever a transaction is saved (both new and edited).
    // - category: user-assigned category label (e.g. "Food", "Transport")
    // - amount: absolute value of the transaction in the user's local currency
    // - type: "credit" or "debit"
    static func trackTransactionAdded(category: String, amount: Double, type: String) {
        Analytics.logEvent("transaction_added", parameters: [
            "category": category,
            "amount": amount,
            "transaction_type": type
        ])
    }

    // Logged when the main dashboard/summary screen becomes visible.
    static func trackDashboardViewed() {
        Analytics.logEvent("dashboard_viewed", parameters: nil)
    }

    // Logged when the user shares a transaction summary via SMS.
    static func trackSMSShared() {
        Analytics.logEvent("sms_shared", parameters: nil)
    }

    // Logged when the user changes the active filter on the transaction list.
    // - filterType: the dimension being filtered, e.g. "date_range", "category", "type"
    static func trackFilterApplied(filterType: String) {
        Analytics.logEvent("filter_applied", parameters: [
            "filter_type": filterType
        ])
    }

    // Logged when the user interacts with a home-screen widget.
    // - widgetType: e.g. "balance_summary", "recent_transactions"
    static func trackWidgetInteraction(widgetType: String) {
        Analytics.logEvent("widget_interaction", parameters: [
            "widget_type": widgetType
        ])
    }

    // Logged for non-fatal errors that are surfaced to the user (e.g. SMS
    // parse failures, SwiftData errors). Complement with CrashlyticsService.recordError
    // for full stack traces.
    static func trackError(domain: String, code: Int, description: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_domain": domain,
            "error_code": code,
            "error_description": description
        ])
    }
}

#else

// Stub used when the FirebaseAnalytics SDK is not linked.
enum AnalyticsService {

    static func trackAppLaunch() {
        print("[AnalyticsService] trackAppLaunch")
    }

    static func trackTransactionAdded(category: String, amount: Double, type: String) {
        print("[AnalyticsService] trackTransactionAdded — category: \(category), amount: \(amount), type: \(type)")
    }

    static func trackDashboardViewed() {
        print("[AnalyticsService] trackDashboardViewed")
    }

    static func trackSMSShared() {
        print("[AnalyticsService] trackSMSShared")
    }

    static func trackFilterApplied(filterType: String) {
        print("[AnalyticsService] trackFilterApplied — filterType: \(filterType)")
    }

    static func trackWidgetInteraction(widgetType: String) {
        print("[AnalyticsService] trackWidgetInteraction — widgetType: \(widgetType)")
    }

    static func trackError(domain: String, code: Int, description: String) {
        print("[AnalyticsService] trackError — domain: \(domain), code: \(code), description: \(description)")
    }
}

#endif
