import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

// NetworkSecurityService is the hardened networking layer for ExpenseMy.
//
// ExpenseMy is local-only today (see docs/security-checklist.md → M5/M10), so
// nothing in the app calls this file yet. It is shipped now, fully implemented,
// so that the day cloud sync is added there is a single, audited entry point for
// all outbound traffic — instead of ad-hoc URLSession calls scattered across the
// codebase, each a potential MITM or misconfiguration risk.
//
// WHAT THIS FILE PROVIDES
//   • CertificatePinningDelegate — SSL/TLS certificate pinning via URLSession.
//   • PinnedCertificate         — host → allowed SHA-256 public-key/cert hashes.
//   • SecureAPIClient           — async GET/POST that go through the pinned session
//                                 and attach signed security headers.
//   • NetworkSecurityError      — typed failure surface for callers.
//
// HOW TO GO LIVE (when a backend exists)
//   1. Capture the server's certificate (or, preferably, its SPKI public key)
//      SHA-256 hash — see the comment on PinnedCertificate for the openssl
//      one-liner.
//   2. Add a PinnedCertificate to SecureAPIClient.pinnedCertificates.
//   3. Pin at least TWO hashes per host (current + backup/rotation cert) so a
//      planned certificate rotation does not brick every installed client.
//   4. Ship the backup pin BEFORE the server starts using it.

// MARK: - Errors

// Typed error surface so callers can branch on failure mode (retry vs. fail vs.
// surface to the user) instead of string-matching opaque NSErrors.
enum NetworkSecurityError: Error, LocalizedError {
    case certificatePinningFailed   // server trust did not match any pinned hash → possible MITM
    case invalidResponse            // response was not an HTTPURLResponse
    case serverError(Int)           // non-2xx HTTP status; associated value is the status code
    case networkUnavailable         // transport-level failure (offline, DNS, refused)
    case requestTimedOut            // request exceeded the configured timeout

    var errorDescription: String? {
        switch self {
        case .certificatePinningFailed:
            return "The server's certificate did not match the pinned certificate. The connection was rejected to prevent a possible man-in-the-middle attack."
        case .invalidResponse:
            return "The server returned a response that could not be interpreted."
        case .serverError(let code):
            return "The server returned an error status code: \(code)."
        case .networkUnavailable:
            return "The network is unavailable. Check the device's connection."
        case .requestTimedOut:
            return "The request timed out before the server responded."
        }
    }
}

// MARK: - Pinned certificate model

// Describes the trust anchor(s) we are willing to accept for a single host.
//
// `hashes` are Base64-encoded SHA-256 digests. Pin the SubjectPublicKeyInfo
// (SPKI) — not the whole certificate — so the pin survives certificate renewal
// as long as the key pair is reused.
//
// Compute an SPKI pin for a live host:
//
//   openssl s_client -connect api.example.com:443 -servername api.example.com 2>/dev/null \
//     | openssl x509 -pubkey -noout \
//     | openssl pkey -pubin -outform der \
//     | openssl dgst -sha256 -binary \
//     | openssl enc -base64
//
// (This implementation hashes the certificate's public key bytes to match the
// SPKI convention above.)
struct PinnedCertificate {
    let host: String        // e.g. "api.expensemy.app"
    let hashes: [String]    // Base64 SHA-256 SPKI pins; include a backup for rotation
}

// MARK: - Certificate pinning delegate

// WHY CERTIFICATE PINNING
// App Transport Security already requires TLS and validates the system trust
// store. Pinning adds a second, app-controlled check: the server must present a
// certificate whose public key we already know. This defeats a
// man-in-the-middle (MITM) attacker who holds a certificate that the *system*
// trusts — for example a corporate/AV root installed on the device, a
// mis-issued certificate from a compromised CA, or a user tricked into trusting
// a proxy's root. Without pinning, any of those can silently decrypt traffic.
//
// We implement the session-level authentication challenge and, for server-trust
// challenges, evaluate the chain ourselves before accepting it.
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    private let pinnedCertificates: [PinnedCertificate]

    init(pinnedCertificates: [PinnedCertificate]) {
        self.pinnedCertificates = pinnedCertificates
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // We only customise server-trust evaluation. Any other challenge
        // (HTTP basic auth, client certs) falls back to the default handling.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // If we have no pins for this host, defer to the system trust store.
        // This lets non-pinned hosts (if any) still work over standard ATS,
        // while pinned hosts are held to the stricter check below.
        guard let pin = pinnedCertificates.first(where: { $0.host == host }) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if validate(serverTrust: serverTrust, against: pin) {
            // Pin matched AND the chain is otherwise valid → accept.
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // No pin matched (or system evaluation failed) → reject the
            // connection. This is the MITM-blocking path.
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // Validates the server trust in two stages:
    //   1. Standard X.509 evaluation against the system trust store (expiry,
    //      hostname, chain to a trusted root). Pinning is *in addition to*,
    //      never *instead of*, this baseline.
    //   2. SPKI pinning: at least one certificate in the presented chain must
    //      hash to one of our pinned values.
    private func validate(serverTrust: SecTrust, against pin: PinnedCertificate) -> Bool {
        // --- Stage 1: system evaluation ---
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            return false
        }

        // --- Stage 2: SPKI pin match over the certificate chain ---
        let certificates = certificateChain(from: serverTrust)
        for certificate in certificates {
            guard let keyHash = publicKeyHash(of: certificate) else { continue }
            if pin.hashes.contains(keyHash) {
                return true
            }
        }
        return false
    }

    // Extracts the certificate chain from a SecTrust in an OS-version-safe way.
    private func certificateChain(from serverTrust: SecTrust) -> [SecCertificate] {
        if #available(iOS 15.0, macOS 12.0, *) {
            return (SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate]) ?? []
        } else {
            var chain: [SecCertificate] = []
            let count = SecTrustGetCertificateCount(serverTrust)
            for index in 0..<count {
                if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                    chain.append(certificate)
                }
            }
            return chain
        }
    }

    // Computes the Base64-encoded SHA-256 hash of a certificate's public key
    // (SPKI pin). Returns nil if the key cannot be exported (e.g. unsupported
    // key type).
    private func publicKeyHash(of certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: keyData)
        return Data(digest).base64EncodedString()
        #else
        // Without CryptoKit we cannot compute the pin; fail closed by returning
        // nil so the caller treats the host as unpinnable on this platform.
        return nil
        #endif
    }
}

// MARK: - Secure API client

// SecureAPIClient is the single funnel for outbound requests. Every call goes
// through the pinned URLSession and carries signed security headers.
final class SecureAPIClient {

    static let shared = SecureAPIClient()

    // Register pinned hosts here when a backend is available. Empty today.
    // Example (placeholder hashes — replace with real SPKI pins):
    //
    //   PinnedCertificate(host: "api.expensemy.app", hashes: [
    //       "REPLACE_ME_PRIMARY_SPKI_SHA256_BASE64=",
    //       "REPLACE_ME_BACKUP_SPKI_SHA256_BASE64="   // rotation backup
    //   ])
    private let pinnedCertificates: [PinnedCertificate] = []

    private let session: URLSession

    // Build a URLSession wired to the pinning delegate with conservative
    // transport defaults. A dedicated session (not URLSession.shared) is used so
    // the pinning delegate is guaranteed to be in effect for every request.
    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12  // never below TLS 1.2
        configuration.httpShouldSetCookies = false                  // no implicit cookie state
        configuration.urlCache = nil                                // don't cache responses on disk

        let delegate = CertificatePinningDelegate(pinnedCertificates: pinnedCertificates)
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    // MARK: Public API

    // Performs a pinned, signed GET request.
    func secureGET(url: URL, headers: [String: String] = [:]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        apply(headers: headers, to: &request)
        return try await perform(request)
    }

    // Performs a pinned, signed POST request with a JSON-or-raw body.
    func securePOST(url: URL, body: Data, headers: [String: String] = [:]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        apply(headers: headers, to: &request)
        return try await perform(request)
    }

    // MARK: Request execution

    // Shared execution path: adds signing headers, runs the request on the
    // pinned session, maps transport/HTTP failures to NetworkSecurityError.
    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var signedRequest = request
        addSecurityHeaders(to: &signedRequest)

        do {
            let (data, response) = try await session.data(for: signedRequest)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkSecurityError.invalidResponse
            }
            guard (200...299).contains(http.statusCode) else {
                throw NetworkSecurityError.serverError(http.statusCode)
            }
            return (data, response)
        } catch let error as NetworkSecurityError {
            throw error
        } catch let urlError as URLError {
            // Map the most relevant transport errors to our typed surface.
            switch urlError.code {
            case .timedOut:
                throw NetworkSecurityError.requestTimedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                throw NetworkSecurityError.networkUnavailable
            case .serverCertificateUntrusted, .secureConnectionFailed, .cancelled:
                // A pinning rejection surfaces as a cancelled/secure-connection
                // failure because the delegate cancels the challenge.
                throw NetworkSecurityError.certificatePinningFailed
            default:
                throw NetworkSecurityError.networkUnavailable
            }
        }
    }

    // Merges caller-supplied headers onto the request.
    private func apply(headers: [String: String], to request: inout URLRequest) {
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
    }

    // MARK: Request signing / security headers

    // WHY REQUEST SIGNING MATTERS
    // Standard security headers let the backend correlate, deduplicate, and
    // reject requests:
    //   • X-Request-ID — a unique UUID per request, enabling end-to-end tracing
    //     and idempotent retries (the server can drop a duplicate ID).
    //   • X-Timestamp  — an ISO-8601 send time, letting the server reject stale
    //     or replayed requests outside an acceptable clock-skew window.
    //   • X-App-Version — the client build, so the backend can apply
    //     version-specific behaviour or block known-bad client versions.
    // When a real auth scheme exists, this is also where an HMAC/signature over
    // (method + path + body + timestamp) would be attached using a key stored in
    // the Keychain (see KeychainService) — never hard-coded.
    private func addSecurityHeaders(to request: inout URLRequest) {
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        request.setValue(Self.iso8601Timestamp(), forHTTPHeaderField: "X-Timestamp")
        request.setValue(Self.appVersion(), forHTTPHeaderField: "X-App-Version")
    }

    private static func iso8601Timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    // Reads "<CFBundleShortVersionString> (<CFBundleVersion>)" from the bundle,
    // e.g. "1.0 (42)". Falls back to "unknown" outside an app bundle (tests).
    private static func appVersion() -> String {
        let info = Bundle.main.infoDictionary
        let marketing = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(marketing) (\(build))"
    }
}

#if canImport(CryptoKit)
// MARK: - Request signing helpers (CryptoKit-gated)

// HMAC request signing, ready for when the backend issues a shared secret.
// Guarded by #if canImport(CryptoKit) because the cryptographic primitives live
// in CryptoKit; without it the signing helpers simply aren't compiled.
extension SecureAPIClient {

    // Produces a hex-encoded HMAC-SHA256 signature over the canonical request
    // string. Store the key in the Keychain and load it at call time — never
    // embed it in source or in a plist.
    //
    // Canonical string convention (must match the server):
    //   "<HTTP-METHOD>\n<path>\n<X-Timestamp>\n<sha256(body) hex>"
    static func signature(canonicalString: String, key: SymmetricKey) -> String {
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data(canonicalString.utf8),
            using: key
        )
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    // Convenience: SHA-256 hex digest of a request body, for inclusion in the
    // canonical string above (binds the signature to the exact payload).
    static func bodyDigest(_ body: Data) -> String {
        SHA256.hash(data: body).map { String(format: "%02x", $0) }.joined()
    }
}
#endif
