# Security Policy

## Supported Versions

Security fixes are applied to the latest released version on `main`. Because
the app ships as a self-contained binary with no backend, old builds are not
patched retroactively — users should update to the newest release.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report privately using one of these channels:

- **GitHub Security Advisories (preferred):** open a private vulnerability
  report at
  https://github.com/yahyaouifaouzi/the-muslims-companion/security/advisories/new
  — this keeps the report confidential until a fix is available.
- **Email:** send details to the address listed on the maintainer's GitHub
  profile (https://github.com/yahyaouifaouzi). Replace `yahyaouifaouzi` with
  your handle if the repository is transferred.

### What to include

- Description of the vulnerability and its impact
- Steps to reproduce (PoC, affected version/commit)
- Any suggested fix, if you have one

### What to expect

- **Acknowledgement** within 72 hours of your report
- **Status update** within 7 days, with an initial assessment
- **Fix / mitigation** targeted within 30 days for medium and high severity,
  coordinated with you on disclosure timing
- Credit in the release notes if you want to be acknowledged

## Scope

This app has **no backend, no accounts, no analytics, and no network calls for
core features**. The only outbound network use is optional remote content
updates (see `docs/CONTENT_PUBLISHING.md`). Valid reports include, but are not
limited to:

- Unsafe handling of bundled or remotely fetched content
- Path traversal or arbitrary file write in the offline content cache
- Insecure inter-app sharing / exported components on Android
- Dependency vulnerabilities with a realistic exploit path in this app

Issues in third-party plugins should be reported upstream; we will help
coordinate an upgrade where warranted.
