# Implementation Plan — رفيق المسلم (The Muslim's Companion)

Status: **Re-inspected during Prompt 00 (2026-10-13); updated after Prompt 05.**
Milestones 01–05 are implemented; checks are green. Next up: Prompt 06.

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
- `test/` — 4 files, **46 tests, all passing**: model parsing/validation,
  repository fixtures (valid/missing/duplicate/malformed), shell/RTL/empty/
  error widget tests, reader font-bound/share-text tests, real-asset smoke
  test.
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
| 05 | Reader screen: font size, copy/share, verbatim Arabic | ✅ Done (new `lib/ui/screens/reader_screen.dart`) |
| 06 | Search + Arabic normalization + persistent favorites | ⬜ Not started (search is an entry-point stub; Favorites tab shows empty state) |
| 07 | Adhkar repetition counter | ⬜ Not started |
| 08 | Hybrid remote JSON updates + offline cache/rollback | ⬜ Not started (repo is local-only; `http`/`path_provider` not yet deps) |
| 09 | Daily local notifications + settings | ⬜ Not started (no `flutter_local_notifications` dep) |
| 10 | Accessibility & polish pass | ⬜ Not started |
| 11 | Release readiness (identity, signing, checklist) | ⬜ Not started |

### Baseline checks (run this session)

- `flutter doctor` → No issues found ✓
- `flutter analyze` → No issues found (exit 0) ✓
- `flutter test` → 46/46 passed (exit 0) ✓

### Known gaps / housekeeping

- Android identity still template values: `applicationId =
  com.example.the_muslims_companion`, launcher label `the_muslims_companion`
  (Prompt 11 scope).
- `pubspec.yaml` description still says "Milestone 1 (foundation)" — stale
  wording, cosmetic.
- `shared_preferences` is installed but unused in `lib/` yet — reserved for
  Prompt 06 (favorites persistence); `share_plus` is now used by the reader.
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

Send **Prompt 06** (search, Arabic normalization, persistent favorites) from
`CLAUDE_CODE_PROMPTS.md`. Starting points: the search stub snackbar in
`home_screen.dart`, the empty `favorites_screen.dart`, and the unused
`shared_preferences` dependency. Preserve the green working tree and the 46
passing tests.
