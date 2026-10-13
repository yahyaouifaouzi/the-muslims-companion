# Content Publishing Guide — رفيق المسلم

This document explains how to host and publish a content release for remote
updates. The app fetches content from a single fixed HTTPS base URL and
validates every file before activating it.

## Hosting requirements

- **HTTPS only.** The app rejects non-HTTPS URLs at the client level.
- **Fixed base URL.** The base URL is compiled into the app
  (`kContentBaseUrl` in `lib/main.dart`). A downloaded manifest can never
  redirect the app to a different host.
- **Serve plain JSON files** (UTF-8, `application/json` charset) at
  predictable paths under the base URL.

## File layout on the server

Given base URL `https://content.example.com/v1`, the app fetches:

| Path | Purpose |
|---|---|
| `https://content.example.com/v1/manifest.json` | Snapshot metadata |
| `https://content.example.com/v1/categories.json` | Categories |
| `https://content.example.com/v1/duas.json` | Duas entries |
| `https://content.example.com/v1/hadiths.json` | Hadiths entries |
| `https://content.example.com/v1/adhkar.json` | Adhkar entries |

All file names must match the app's fixed allow-list
(`kAllowedContentFiles` in `lib/content/local_content_repository.dart`).

## manifest.json

```json
{
  "schemaVersion": 1,
  "contentVersion": 2,
  "updatedAt": "2026-10-14",
  "files": ["categories.json", "duas.json", "hadiths.json", "adhkar.json"]
}
```

- `schemaVersion`: must be `1` (the current JSON contract). Bump only when
  field structures change — and only after the app ships a version that
  understands the new schema.
- `contentVersion`: integer that **must increase** with every content
  revision. The app skips downloads when the remote version is not greater
  than the active local version.
- `updatedAt`: ISO-8601 date string for display in the app's settings.
- `files`: every content file that makes up this snapshot. `categories.json`
  is required. File names must be from the allow-list.

## Publishing a release

1. Edit the JSON files under `assets/data/` (or your publishing source).
2. Bump `contentVersion` in `manifest.json`.
3. Set `updatedAt` to today's date.
4. Validate locally: run `flutter test` — the repository tests exercise the
   same validation the app uses at refresh time.
5. Upload **all** files listed in `files` (plus `manifest.json`) to the
   server under the base URL path.
6. Verify: `curl https://content.example.com/v1/manifest.json` returns the
   new version.

## What the app validates before activating

Every refresh runs the full validation pipeline:

- Manifest schema and file allow-list.
- Each file decodes as UTF-8 JSON and matches the expected schema.
- Entry IDs are unique across all files.
- Every entry's `categoryId` references an existing category in the same
  content file.
- No arbitrary file paths from remote JSON.

If **any** file fails validation, the entire update is rejected and the
previous snapshot (or bundled assets) remains active. Partial downloads never
replace a valid snapshot.

## Security assumptions

- The base URL is a build-time constant — the remote server cannot redirect
  the app to arbitrary hosts or private IPs.
- There is **no cryptographic integrity or authenticity verification** in
  this version. Content integrity relies on HTTPS transport security and
  full schema/cross-reference validation. If signed content is needed later,
  add a signature verification step before activation.
- Response size is capped (2 MB per file) and requests time out (15 s) to
  bound resource usage.

## Rollback

To roll back a bad release: re-upload the previous known-good files and
increment `contentVersion` (never decrease it — the app ignores older or
equal versions). Users who already downloaded the bad version will pick up
the rollback on their next refresh.
