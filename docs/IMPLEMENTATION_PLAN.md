# Implementation Plan — رفيق المسلم (The Muslim's Companion)

Status: **Re-inspected during Prompt 00 (2026-10-13).** Milestones 01–04 are
implemented and committed (`01`…`04`); checks are green. Next up: Prompt 05.

## 1. Current environment

| Item | Status |
|------|--------|
| OS | Ubuntu 24.04.5 LTS (locale `fr_FR.UTF-8`) |
| Flutter SDK | **3.47.7 stable** at `$HOME/flutter` (not necessarily on a fresh shell's PATH) |
| Dart SDK | 3.13.5 (bundled with Flutter); pubspec constraint `^3.13.5` |
| Android toolchain | ✓ Android SDK 36.0.0 (`flutter doctor` passes) |
| `flutter doctor` | **No issues found** (Chrome + Linux desktop also available) |
| Git | branch `master`, working tree clean. History: `INIT` → `INIT Flutter` → `01` → `02` → `03` → `04` → `MCP` |

## 2. Current project status

A real app now exists (the earlier "nothing implemented" snapshot is obsolete):

- `lib/main.dart` — app shell: `ar` locale, RTL, Material 3 theme, provider wiring.
- `lib/app/` — `content_provider.dart` (loading/error/catalog states),
  `theme/app_theme.dart` (green/off-white/beige).
- `lib/content/` — typed models + `LocalContentRepository` with file allow-list
  (`kAllowedContentFiles`), cross-validation, typed `ContentException`,
  injectable `JsonDocumentLoader` for tests.
- `lib/ui/` — `MainShell` (`IndexedStack`: Home / Favorites / Settings bottom
  nav), Categories, Category detail, dynamic category cards, shared
  loading/empty/error views, icon mapper.
- `assets/data/` — manifest, categories, duas, hadiths, adhkar JSON,
  registered in `pubspec.yaml`.
- `docs/CONTENT_SCHEMA.md` — JSON contract (schemaVersion vs contentVersion,
  placeholder policy).
- `test/` — 4 files, **38 tests, all passing**: model parsing/validation,
  repository fixtures (valid/missing/duplicate/malformed), shell/RTL/empty/
  error widget tests, real-asset smoke test.
- `README.md` — setup, run, and check commands.
- `AGENTS.md` / `GEMINI.md` / `.claude/` / `opencode.json` — agent tooling
  (graft context graph) added by the `MCP` commit; `graft/` is local-only
  (gitignored, rebuild with `graft build`).

### Milestone status (mapped to CLAUDE_CODE_PROMPTS.md)

| Prompt | Milestone | Status |
|--------|-----------|--------|
| 01 | Foundation: deps, Arabic locale + RTL, theme, structure, assets | ✅ Done (commit `01`) |
| 02 | Content models + bundled JSON + schema doc + tests | ✅ Done (commit `02`) |
| 03 | Local content repository (allow-list, typed errors, tests) | ✅ Done (commit `03`) |
| 04 | App shell, home/categories/detail, states, widget tests | ✅ Done (commit `04`) |
| 05 | Reader screen: font size, copy/share, verbatim Arabic | ⬜ Not started |
| 06 | Search + Arabic normalization + persistent favorites | ⬜ Not started (search is an entry-point stub; Favorites tab shows empty state) |
| 07 | Adhkar repetition counter | ⬜ Not started |
| 08 | Hybrid remote JSON updates + offline cache/rollback | ⬜ Not started (repo is local-only; `http`/`path_provider` not yet deps) |
| 09 | Daily local notifications + settings | ⬜ Not started (no `flutter_local_notifications` dep) |
| 10 | Accessibility & polish pass | ⬜ Not started |
| 11 | Release readiness (identity, signing, checklist) | ⬜ Not started |

### Baseline checks (run this session)

- `flutter doctor` → No issues found ✓
- `flutter analyze` → No issues found (exit 0) ✓
- `flutter test` → 38/38 passed (exit 0) ✓

### Known gaps / housekeeping

- Android identity still template values: `applicationId =
  com.example.the_muslims_companion`, launcher label `the_muslims_companion`
  (Prompt 11 scope).
- `pubspec.yaml` description still says "Milestone 1 (foundation)" — stale
  wording, cosmetic.
- `shared_preferences` and `share_plus` are installed but unused in `lib/`
  yet — reserved for Prompts 05/06.
- `docs/IMPLEMENTATION_PLAN.md` milestones 08/09 mention docs
  (`CONTENT_PUBLISHING.md`, `RELEASE_CHECKLIST.md`) that don't exist yet.

## 3. Architecture rules (carried across all milestones)

- Flutter/Dart, Android first; Arabic-only UI, RTL; Material 3 deep green /
  off-white / beige.
- Bundled JSON is the initial source of truth; remote updates + offline cache
  come later (Prompt 08).
- Features: categories with icons, search, favorites, copy/share, adhkar
  counter, daily notifications, adjustable font size.
- No backend, database, login, analytics, ads, or Firebase in the MVP.
- **Never invent** Quranic verses, hadiths, sources, authenticity grades, or
  prescribed repetition counts. Unverified content is clearly labelled as
  placeholders and excluded from production until verified.
- Layout must stay Directionality-aware (`EdgeInsetsDirectional`,
  `AlignmentDirectional`, start/end) — never hardcode left/right.
- Malformed content raises typed `ContentException`; never silently render an
  empty list.

## 4. Immediate next action

Send **Prompt 05** (reader screen, text settings, copy/share) from
`CLAUDE_CODE_PROMPTS.md`. Existing `share_plus` dep and the reader-less
`category_detail_screen.dart` are the starting points. Preserve the green
working tree and the 38 passing tests.
