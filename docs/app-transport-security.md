# App Transport Security (ATS) — ExpenseMy Guide

Last reviewed: 2026-05-19

---

## What Is App Transport Security?

App Transport Security (ATS) is Apple's built-in network security policy, introduced in iOS 9 and enforced for all App Store apps. It requires that all HTTP connections use HTTPS with strong TLS settings. Apple's App Review team will reject apps that add unjustified ATS exceptions.

ATS enforces, by default:

| Requirement | Default |
|-------------|---------|
| Protocol | HTTPS only (HTTP blocked) |
| Minimum TLS version | TLS 1.2 |
| Forward secrecy | Required (ECDHE key exchange) |
| Certificate validity | Must chain to a trusted CA |
| SHA-1 certificates | Rejected |

---

## Current Status: No Network Calls

ExpenseMy **does not make any network calls** in its current version (0.1.0). The app operates entirely locally:

- SMS parsing is done on-device using regex.
- Transaction data is stored in SwiftData (local SQLite).
- The Share Extension passes data via an App Group container (inter-process, not network).
- WidgetKit reads from the same App Group container.

Because there are no network calls, the `Info.plist` does not contain an `NSAppTransportSecurity` key, and the OS-level ATS defaults apply. **This is the correct and most secure configuration.**

---

## Rules for When Networking Is Added

When any cloud sync, analytics, or API feature is introduced, the following rules apply **without exception**:

### 1. No ATS Exceptions

Do not add any of the following to `Info.plist`:

```xml
<!-- NEVER add these -->
<key>NSAllowsArbitraryLoads</key>
<true/>
<key>NSExceptionAllowsInsecureHTTPLoads</key>
<true/>
<key>NSAllowsArbitraryLoadsInWebContent</key>
<true/>
```

If a third-party SDK or service requires an ATS exception, treat that as a blocker and find an alternative, or raise it as a security issue.

### 2. Minimum TLS 1.2, Prefer TLS 1.3

ATS enforces TLS 1.2 as the floor. For ExpenseMy-controlled backends, configure the server to prefer TLS 1.3 (supported since iOS 13).

Verify server TLS configuration with:

```bash
nmap --script ssl-enum-ciphers -p 443 api.expensemy.example.com
# or
openssl s_client -connect api.expensemy.example.com:443 -tls1_2
```

### 3. Certificate Pinning Is Required

ATS validates that a certificate chains to a trusted CA, but it does not prevent certificate misissuance by other CAs (e.g., a compromised or rogue CA). Certificate pinning closes this gap by checking that the server presents a specific certificate or public key.

**Pin the public key (SPKI), not the leaf certificate**, so that routine certificate renewals don't break the app.

---

## Correct `NSAppTransportSecurity` Configuration

When you do have servers, declare them explicitly rather than using `NSAllowsArbitraryLoads`:

```xml
<!-- In Info.plist — only add if you have specific domains -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Uncomment and fill in only for known domains -->
    <!--
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.expensemy.example.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
    </dict>
    -->
</dict>
```

Prefer keeping `Info.plist` free of `NSAppTransportSecurity` entirely — the defaults are already strict.

---

## Certificate Pinning Implementation in Swift

Use a `URLSession` delegate to inspect the server's certificate chain during the TLS handshake. This is the only reliable way to pin in Swift without a third-party library.

### Step 1 — Extract the Public Key Hash

```bash
# Get the leaf certificate's public key SHA-256 hash (base64)
openssl s_client -connect api.expensemy.example.com:443 </dev/null 2>/dev/null \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | base64
```

Store the resulting base64 string in your app (not in `UserDefaults` — embed it as a compile-time constant).

### Step 2 — Implement the URLSession Delegate

```swift
import Foundation
import CryptoKit

final class PinnedSessionDelegate: NSObject, URLSessionDelegate {

    // SHA-256 hashes of allowed Subject Public Key Info (SPKI) DER bytes, base64-encoded.
    // Add the backup pin (next certificate) alongside the current one.
    private let pinnedPublicKeyHashes: Set<String> = [
        "REPLACE_WITH_PRIMARY_SPKI_HASH",   // current certificate
        "REPLACE_WITH_BACKUP_SPKI_HASH",    // next/backup certificate
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust,
            SecTrustEvaluateWithError(serverTrust, nil),
            let leafCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let publicKey = SecCertificateCopyKey(leafCertificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Hash the raw public key bytes
        let hash = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if pinnedPublicKeyHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Pin mismatch — possible MITM attack
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### Step 3 — Use the Delegate in URLSession

```swift
let delegate = PinnedSessionDelegate()
let session = URLSession(
    configuration: .default,
    delegate: delegate,
    delegateQueue: nil
)

let task = session.dataTask(with: URLRequest(url: apiURL)) { data, response, error in
    // handle response
}
task.resume()
```

### Step 4 — Backup Pins and Rotation

- Always include **at least two pins**: the current certificate's SPKI hash and the next one.
- Before rotating a certificate on the server, ship an app update that adds the new certificate's pin to the set.
- Never leave the app with only one pin — a failed rotation will lock all users out of the service.

---

## Testing Certificate Pinning

Use a proxy tool (Charles, mitmproxy) in a debug build to verify that:
1. Normal HTTPS traffic to the pinned domain succeeds.
2. Traffic intercepted by the proxy (which presents its own certificate) is rejected with a `cancelAuthenticationChallenge`.

Add a `#if DEBUG` bypass in the delegate if needed for development, but **never ship the bypass in a Release build**.

---

## Summary Checklist

- [ ] No `NSAllowsArbitraryLoads` in `Info.plist`
- [ ] All backend servers use TLS 1.2+ (prefer 1.3)
- [ ] Certificate pinning implemented via `URLSessionDelegate`
- [ ] At least two SPKI pins configured (primary + backup)
- [ ] Pin rotation procedure documented before any server cert expires
- [ ] ATS pinning verified with a proxy tool in a development build
