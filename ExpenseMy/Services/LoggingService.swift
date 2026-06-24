import Foundation
import os

// LoggingService is the single, structured logging entry point for ExpenseMy.
//
// WHY A WRAPPER INSTEAD OF print()
//   • print() writes to stdout only, is stripped of context, and (critically for
//     a financial app) can leak sensitive data into device logs readable by a
//     connected Mac — see docs/security-checklist.md → M6.
//   • Apple's unified logging (os.Logger) is structured, queryable in Console.app
//     and `log` CLI, low-overhead, and respects privacy redaction.
//
// WHAT THIS GIVES YOU
//   • A typed LogLevel that maps to OSLogType.
//   • Stable categories so logs can be filtered by subsystem area.
//   • Automatic call-site capture (file/function/line).
//   • DEBUG-only console mirroring with emoji prefixes for fast scanning.
//   • Forwarding of error/critical logs to Crashlytics breadcrumbs.
//   • A redact() helper that hides sensitive values in release builds.
//
// USAGE
//   LoggingService.log("Parsed SMS into transaction", level: .info,
//                      category: LoggingService.Category.parser)
//   LoggingService.log("Keychain write failed", level: .error,
//                      category: LoggingService.Category.security)

enum LogLevel {
    case debug
    case info
    case warning
    case error
    case critical

    // Maps our level to Apple's unified-logging type. Note os semantics:
    //   .debug — not persisted by default; for development noise.
    //   .info  — persisted only while a capture is active.
    //   .default (.warning) — persisted, normal signal.
    //   .error / .fault — always persisted; .fault is for serious failures.
    var osLogType: OSLogType {
        switch self {
        case .debug:    return .debug
        case .info:     return .info
        case .warning:  return .default
        case .error:    return .error
        case .critical: return .fault
        }
    }

    // Emoji used by the DEBUG console mirror for at-a-glance triage.
    var emoji: String {
        switch self {
        case .debug:    return "🟢"
        case .info:     return "🔵"
        case .warning:  return "🟡"
        case .error:    return "🔴"
        case .critical: return "💀"
        }
    }

    // Human-readable label included in the console mirror.
    var label: String {
        switch self {
        case .debug:    return "DEBUG"
        case .info:     return "INFO"
        case .warning:  return "WARNING"
        case .error:    return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

enum LoggingService {

    // Stable category strings. Using constants (not raw strings at the call
    // site) keeps Console.app filters consistent and refactors safe.
    enum Category {
        static let parser    = "parser"     // SmsParser, categorisation
        static let storage   = "storage"    // SwiftData, SecureStorage, Keychain
        static let analytics = "analytics"  // AnalyticsService events
        static let network   = "network"    // NetworkSecurityService / future sync
        static let ui         = "ui"        // view lifecycle, navigation
        static let security  = "security"   // auth, pinning, keychain failures
    }

    // The subsystem groups all of this app's logs under one identifier in
    // Console.app. Falls back to a constant if the bundle id is unavailable
    // (e.g. unit-test host).
    private static let subsystem = Bundle.main.bundleIdentifier ?? "learns.ExpenseMy"

    // os.Logger instances are cheap but we cache one per category to avoid
    // recreating them on every call.
    private static var loggers: [String: Logger] = [:]
    private static let loggersLock = NSLock()

    private static func logger(for category: String) -> Logger {
        loggersLock.lock()
        defer { loggersLock.unlock() }
        if let existing = loggers[category] {
            return existing
        }
        let created = Logger(subsystem: subsystem, category: category)
        loggers[category] = created
        return created
    }

    // MARK: - Primary API

    // Logs a message through unified logging, mirrors to the console in DEBUG,
    // and forwards error/critical entries to Crashlytics as breadcrumbs.
    //
    // file/function/line default to the call site via #file/#function/#line, so
    // callers never pass them explicitly.
    static func log(
        _ message: String,
        level: LogLevel,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logger = logger(for: category)

        // Unified logging. The message is marked %{public} because callers are
        // responsible for redacting sensitive values via redact() BEFORE passing
        // them in — see the redact() contract below. This keeps useful logs
        // readable while never logging raw secrets.
        logger.log(level: level.osLogType, "[\(category, privacy: .public)] \(message, privacy: .public) (\(fileName, privacy: .public):\(line, privacy: .public) \(function, privacy: .public))")

        // DEBUG-only console mirror with emoji prefixes for fast scanning.
        #if DEBUG
        print("\(level.emoji) [\(level.label)] [\(category)] \(message) — \(fileName):\(line) \(function)")
        #endif

        // Forward higher-severity logs to Crashlytics as breadcrumbs so they
        // accompany the next crash report. CrashlyticsService is a no-op stub
        // when the Firebase SDK isn't linked, so this is always safe to call.
        if level == .error || level == .critical {
            CrashlyticsService.log("[\(level.label)][\(category)] \(message) (\(fileName):\(line))")
        }
    }

    // MARK: - Convenience wrappers

    static func debug(_ message: String, category: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    static func info(_ message: String, category: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    static func warning(_ message: String, category: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    static func error(_ message: String, category: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    static func critical(_ message: String, category: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }

    // MARK: - Privacy-aware redaction

    // Redacts a sensitive value before it is logged.
    //
    // CONTRACT:
    //   • Release builds  → always returns "REDACTED". Sensitive data (SMS
    //     bodies, amounts, tokens, account numbers, user IDs) must NEVER reach
    //     persisted device logs in production (OWASP M6 — Inadequate Privacy).
    //   • Debug builds    → returns the original value so developers can inspect
    //     real data on their own machines during development.
    //
    // Always wrap sensitive interpolations, e.g.:
    //   LoggingService.info("Parsed amount \(LoggingService.redact(amountString))",
    //                       category: LoggingService.Category.parser)
    static func redact(_ value: String) -> String {
        #if DEBUG
        return value
        #else
        return "REDACTED"
        #endif
    }
}
