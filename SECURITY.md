# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.0   | Yes       |

Older pre-release builds are not supported. Always use the latest release.

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report security issues by email to the project maintainers:

- **Primary contact:** 1060ashish@gmail.com
- **Subject line:** `[ExpenseMy Security] <brief summary>`

Include:
- A clear description of the vulnerability
- Steps to reproduce or a proof-of-concept (if safe to share)
- The potential impact and affected versions
- Any suggested mitigations

### Response Timeline

| Milestone | Target |
|-----------|--------|
| Acknowledgment | Within 48 hours |
| Initial assessment & severity rating | Within 7 days |
| Fix or mitigation plan communicated | Within 30 days |
| Public disclosure (coordinated) | After fix is released |

We follow responsible disclosure: we will work with you to understand the issue and coordinate a fix before any public disclosure.

---

## Responsible Disclosure Policy

- Please give us a reasonable opportunity to address the issue before public disclosure.
- We will not pursue legal action against researchers who report in good faith.
- We will credit researchers in the release notes unless anonymity is requested.

---

## What Qualifies as a Security Issue

The following categories are in scope:

- **Sensitive data leakage** — SMS content, transaction amounts, or personal financial data exposed beyond the app sandbox
- **Insecure local storage** — credentials or sensitive values stored in `UserDefaults` instead of the Keychain
- **Injection vulnerabilities** — malformed SMS input causing unintended code execution or data corruption
- **Authorization bypass** — accessing or modifying another user's data in any future multi-user scenario
- **Share Extension data exposure** — transaction data leaking through the Share Extension's App Group container to unauthorized apps
- **Dependency vulnerabilities** — a future Swift Package Manager dependency with a known CVE

---

## Out of Scope

The following are **not** security issues:

- UI bugs, visual glitches, or layout regressions
- Feature requests or usability improvements
- Crashes that do not expose sensitive data
- Issues only reproducible on jailbroken devices
- Denial-of-service attacks against a purely local app with no server component
