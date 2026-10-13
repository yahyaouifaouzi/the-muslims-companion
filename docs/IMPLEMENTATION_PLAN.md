# Implementation Plan — رفيق المسلم (The Muslim's Companion)

Status: **Updated after re-running Prompt 00.** A Flutter project now exists (default
template, scaffolded 2026-10-13 10:16). No features implemented yet.

## 1. Current environment

| Item | Status |
|------|--------|
| OS | Ubuntu 24.04.5 LTS (locale `fr_FR.UTF-8`) |
| Flutter SDK | **3.47.7 stable** at `/home/ideasd/flutter` (added to PATH per-session; consider adding to `~/.bashrc`) |
| Dart SDK | 3.13.5 (bundled with Flutter) |
| Android toolchain | ✓ Android SDK 36.0.0 (`flutter doctor` passes) |
| Java | `/usr/bin/java` ✓ |
| `flutter doctor` | **No issues found** (2 devices available) |
| Git | ✓ 2.55.0, repository initialized on branch `master` |

## 2. Current project status

- Working directory: `/home/ideasd/ideas2d/TheMuslimsCompanion` — **is a Flutter project**.
- Scaffold: fresh `flutter create` output (`INIT Flutter` commit `bfcd679` on top of an
  earlier `INIT` commit). Working tree is clean.
- Package name: `the_muslims_companion`, version `1.0.0+1`, SDK constraint `^3.13.5`.
- `lib/`: only the **default counter demo** (`main.dart`, untouched template).
- `test/`: single template widget test (`widget_test.dart`).
- `docs/`: `IMPLEMENTATION_PLAN.md` only.

### Baseline checks (run this session)
- `flutter --version` → Flutter 3.47.7 / Dart 3.13.5 ✓
- `flutter doctor` → No issues found ✓
- `flutter analyze` → No issues found (exit 0) ✓
- `flutter test` → 1/1 passed (exit 0) ✓

### What is missing vs. the target app (mapped to prompts 01–11)

| Prompt | Milestone | Status |
|--------|-----------|--------|
| 01 | Foundation: deps (`provider`, `shared_preferences`, `share_plus`, `flutter_localizations`), Arabic locale + RTL, Material 3 green/white/beige theme, feature-oriented `lib/` structure, `assets/data/` in pubspec | ❌ Not started (default template) |
| 02 | Content models + bundled JSON schemas (manifest, categories, duas, hadiths, adhkar), validations, `docs/CONTENT_SCHEMA.md` | ❌ Not started |
| 03 | Local content repository (typed loading, validation, typed errors) | ❌ Not started |
| 04 | App shell + home/categories/list screens, dynamic category cards, state handling | ❌ Not started |
| 05 | Reader screen: font size, copy/share, verbatim Arabic handling | ❌ Not started |
| 06 | Search + Arabic normalization + persistent favorites | ❌ Not started |
| 07 | Adhkar repetition counter | ❌ Not started |
| 08 | Hybrid remote JSON updates + offline cache with validation/rollback | ❌ Not started |
| 09 | Daily local notifications + settings | ❌ Not started |
| 10 | Accessibility & polish pass | ❌ Not started |
| 11 | Release readiness (signing docs, release checklist) | ❌ Not started |

### Additional gaps / housekeeping known now
- `assets/data/` does not exist yet and no assets are registered in `pubspec.yaml`.
- Default app title/description in `pubspec.yaml` and `main.dart` still say
  "Flutter Demo / A new Flutter project" — will be replaced in Prompt 01.
- Android applicationId and app label are Flutter defaults — review in Prompt 01/11.
- Platform folders for iOS/macOS/Linux/Windows/web exist although the app is
  Android-first; harmless, can stay.

## 3. Architecture rules (carried across all milestones)

- Flutter/Dart, Android first; Arabic-only UI, RTL; Material 3 deep green /
  off-white / beige.
- Bundled JSON is the initial source of truth; remote updates + offline cache
  come later (prompt 08).
- Features: categories with icons, search, favorites, copy/share, adhkar
  counter, daily notifications, adjustable font size.
- No backend, database, login, analytics, ads, or Firebase in the MVP.
- **Never invent** Quranic verses, hadiths, sources, authenticity grades, or
  prescribed repetition counts. Unverified content is clearly labelled as
  placeholders and excluded from production until verified.

## 4. Immediate next action

Ready for **Prompt 01** (project foundation). Nothing in this document was
implemented yet — no features, no dependencies beyond the template.
