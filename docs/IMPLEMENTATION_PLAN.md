# Implementation Plan — رفيق المسلم (The Muslim's Companion)

Status: **Initial plan (Prompt 00).** No implementation has been done yet.

## 1. Current project status

- Working directory: `/home/ideasd/ideas2d/TheMuslimsCompanion`
- Contents: **`CLAUDE_CODE_PROMPTS.md` only.** This is **not** a Flutter project.
- Git repository: **not initialized**.
- Tests: **none** (no test files exist).
- Flutter SDK: **not installed** (not on PATH, not found in common locations).
- Dart SDK: **not installed** / not on PATH.
- Git CLI: available (git 2.55.0).
- OS: Linux (bash available).

## 2. Blockers before implementation can start

1. **Flutter SDK is missing.** `flutter` and `dart` are not installed. No Flutter
   project can be created, analyzed, built, or tested until the SDK is installed.
2. **Git repository is not initialized.** Version control should be set up before
   generating the project so the baseline is recorded.

## 3. Proposed setup commands (awaiting approval — not executed)

```bash
# 1. Initialize version control at the project root
git init

# 2. Install the Flutter SDK (Linux, official tarball method)
cd ~
# Download the latest stable Linux Flutter SDK; check https://docs.flutter.dev/release/archive
# for the exact current filename, then:
#   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_<version>-stable.tar.xz
#   tar xf flutter_linux_<version>-stable.tar.xz   # extracts to ~/flutter
#   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
#   source ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"

# 3. Verify the toolchain (also runs first-run diagnostics)
flutter doctor

# 4. Create the Flutter project in an empty directory (avoid nesting)
cd /home/ideasd/ideas2d
flutter create --org com.example --project-name the_muslims_companion TheMuslimsCompanion
```

Alternative: install Flutter via `snap install flutter --classic` if snap is preferred.

## 4. Milestone plan (mapped to prompts 01–11)

| # | Milestone | Prompt |
|---|-----------|--------|
| 1 | Project foundation: dependencies (`provider`, `shared_preferences`, `share_plus`, `flutter_localizations`), Arabic locale, Material 3 green/white/beige theme, RTL conventions, feature-oriented `lib/` structure, `assets/data/` | 01 |
| 2 | Content models + bundled JSON: manifest, categories, duas, hadiths, adhkar; schemaVersion/contentVersion; validation of required fields, unique IDs, repeat counts; `docs/CONTENT_SCHEMA.md` | 02 |
| 3 | Local content repository: typed asset loading, sort orders, filename/structure validation, typed errors, tests | 03 |
| 4 | App shell + UI: home, categories, favorites placeholder, settings placeholder, category list; dynamic category cards; empty/loading/error states | 04 |
| 5 | Reader screen: adjustable font size, copy, share, verbatim Arabic text, source handling | 05 |
| 6 | Search + favorites: local in-memory search, Arabic normalization (search-only), persistent favorites, stale-ID handling | 06 |
| 7 | Adhkar counter: only on validated `repeatCount` entries or user-defined target; persisted session progress | 07 |
| 8 | Hybrid updates: remote JSON refresh over fixed HTTPS base, staging + validation + rollback, offline cache | 08 |
| 9 | Daily notifications: `flutter_local_notifications`, permission handling, timezone setup | 09 |
| 10 | Accessibility + polish pass | 10 |
| 11 | Release readiness: signing docs, release checklist, no placeholder content in production | 11 |

## 5. Architectural rules (carried across all milestones)

- Flutter/Dart, Android first; Arabic-only UI, RTL; Material 3 in deep green /
  off-white / beige.
- Bundled JSON is the initial source of truth; remote updates + offline cache
  come later (prompt 08).
- Features: categories with icons, search, favorites, copy/share, adhkar
  counter, daily notifications, adjustable font size.
- No backend, database, login, analytics, ads, or Firebase in the MVP.
- **Never invent** Quranic verses, hadiths, sources, authenticity grades, or
  prescribed repetition counts. Unverified content is clearly labelled as
  placeholders and excluded from production until verified.

## 6. Immediate next action

Install the Flutter SDK (or confirm a preferred install method), then run
Prompt 01 to establish project foundation.
