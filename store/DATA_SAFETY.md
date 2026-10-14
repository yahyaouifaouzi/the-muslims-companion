# Google Play Data Safety — form answers

Mirror of what to enter in Play Console → App content → Data safety.
Must stay in sync with `PRIVACY_POLICY.md` and the actual behavior
(last reviewed: 2026-10-14).

## Does your app collect or share any user data?

**No — the app does not collect or share any user data.**

All processing happens on-device. There are no accounts, no analytics, no
crash reporters, no ad SDKs, and no backend owned by the developer.

## Data types checklist (all unchecked)

| Data type | Collected? | Shared? | Required? | Purpose |
|-----------|------------|---------|-----------|---------|
| Personal info (name, email, phone, address, …) | No | No | — | — |
| Photos / videos / audio | No | No | — | — |
| Files and documents | No | No | — | — |
| Calendar (events, tasks) | No | No | — | — |
| Contacts | No | No | — | — |
| App activity (app interactions, installed apps, …) | No | No | — | — |
| Web history | No | No | — | — |
| Device / other IDs | No | No | — | — |
| Location (approximate / precise) | No | No | — | — |
| Health / fitness | No | No | — | — |
| Financial info | No | No | — | — |
| Messages (emails, SMS, …) | No | No | — | — |
| User-generated content | No | No | — | — |
| Search history | No | No | — | — |

Search is entirely local against the bundled content; queries are never
sent anywhere or stored outside the device.

## Network behavior (relevant to "is data collected?")

- The app can optionally fetch a public content JSON snapshot from the
  developer's content host (`kContentBaseUrl`). Requests contain no user
  data: no identifiers, no search queries, no device fingerprints.
- The "report content" button on the in-app about screen opens the
  user's own mail client (mailto). Whatever the user chooses to write in
  that email is sent by the user's mail provider, not by the app; the app
  performs no upload.

## Deletion

Uninstalling the app deletes all locally stored data (favorites, counter
progress, preferences, cached content). The developer stores nothing to
delete server-side.

## Kids

The app is suitable for all ages, does not target children, and collects
no data from anyone — including children.
