# Implementation Plan — رفيق المسلم (The Muslim's Companion)

Status: **Re-inspected during Prompt 00 (2026-10-13); updated after Prompt 10.**
Milestones 01–10 are implemented; checks are green. Next up: Prompt 11.

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
  `favorites_store.dart` (persisted favorite IDs),
  `counter_store.dart` (persisted repetition counts + user-defined targets),
  `theme/app_theme.dart` (green/off-white/beige).
- `lib/content/` — typed models + `LocalContentRepository` with file allow-list
  (`kAllowedContentFiles`), cross-validation, typed `ContentException`,
  injectable `JsonDocumentLoader` for tests. `refresh/` sub-package:
  `ContentCache` (atomic single-file snapshot + shared_preferences metadata),
  `RemoteContentClient` (HTTPS-only, timeout, size limit, path-traversal
  rejection), `ContentRefreshService` (fetch→validate→activate with rollback
  safety).
- `lib/ui/` — `MainShell` (`IndexedStack`: Home / Favorites / Settings bottom
  nav), Categories, Category detail, dynamic category cards, shared
  loading/empty/error views, icon mapper.
- `assets/data/` — manifest, categories, duas, hadiths, adhkar JSON,
  registered in `pubspec.yaml`.
- `docs/CONTENT_SCHEMA.md` — JSON contract (schemaVersion vs contentVersion,
  placeholder policy).
- `docs/CONTENT_PUBLISHING.md` — how to host and publish a content release.
- `test/` — 16 files, **120 tests, all passing**: model parsing/validation,
  repository fixtures (valid/missing/duplicate/malformed), shell/RTL/empty/
  error widget tests, reader font-bound/share-text tests, Arabic search
  normalization/matching, favorites persistence + stale-ID resolution,
  counter increment/reset/persistence/completion, content cache atomicity,
  remote client security constraints, refresh service (unchanged/success/
  timeout/invalid-JSON/duplicate-IDs/bad-category-ref/partial-download/
  rollback), reminder settings persistence + daily next-occurrence/time
parsing, reminder permission/schedule/cancel widget flows, RTL chevron
direction, search performance on 5000 entries, and real-asset smoke test.
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
| 06 | Search + Arabic normalization + persistent favorites | ✅ Done (`search_screen.dart`, `favorites_store.dart`; shared `EntryCard`) |
| 07 | Adhkar repetition counter | ✅ Done (`counter_store.dart`, `counter_section.dart`; large tap target) |
| 08 | Hybrid remote JSON updates + offline cache/rollback | ✅ Done (`content/refresh/`: cache, client, service; Settings refresh UI) |
| 09 | Daily local notifications + settings | ✅ Done (`reminder_store.dart`, `notification_service.dart`, Settings reminder section; inexact-only scheduling) |
| 10 | Accessibility & polish pass | ✅ Done (desugaring config, RTL chevron fix, reminder flow + search perf tests) |
| 11 | Release readiness (identity, signing, checklist) | ⬜ Not started |

### Baseline checks (run this session)

- `flutter doctor` → No issues found ✓
- `flutter analyze` → No issues found (exit 0) ✓
- `flutter test` → 120/120 passed (exit 0) ✓
- `flutter build apk --debug` → ✓ Built
  `build/app/outputs/flutter-apk/app-debug.apk` (187 MB; warning only: the
  `flutter_timezone` plugin applies Kotlin Gradle Plugin — upstream plugin
  issue, not a build failure)

### Known gaps / housekeeping

- Android identity still template values: `applicationId =
  com.example.the_muslims_companion`, launcher label `the_muslims_companion`
  (Prompt 11 scope).
- `pubspec.yaml` description still says "Milestone 1 (foundation)" — stale
  wording, cosmetic.
- `docs/IMPLEMENTATION_PLAN.md` milestone 09 mentions a doc
  (`RELEASE_CHECKLIST.md`) that doesn't exist yet.
- `kContentBaseUrl` in `main.dart` is a placeholder
  (`https://content.example.com/v1`) — must be replaced with the real content
  host before release (see `docs/CONTENT_PUBLISHING.md`).
- No cryptographic content integrity — relies on HTTPS + full validation
  only. Signed content is a future enhancement, documented in
  `CONTENT_PUBLISHING.md`.

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

Send **Prompt 11** (release readiness) from `CLAUDE_CODE_PROMPTS.md`.
Preserve the green working tree and the 120 passing tests.

### Prompt 10 notes (accessibility/quality pass)

- RTL audit: no hardcoded left/right/`EdgeInsets.only` in `lib/`; all layout
  uses directional APIs. Fixed a real RTL bug: the category-card chevron
  passed `textDirection: TextDirection.rtl` to `Icons.chevron_right`, which
  does **not** mirror the glyph — now picks `chevron_left`/`chevron_right`
  from `Directionality.of(context)`.
- Typography: reader uses `height: 1.9` + clamped user font size (system
  scaling still applies); list cards cap lines with ellipsis; Arabic wraps
  freely in reader.
- Touch targets: Material defaults (IconButton 48dp, NavigationBar ≥64dp),
  counter circle 120dp, card InkWells full-width. All icon buttons carry
  Arabic tooltips; screen readers read card/list text; switch has a title.
- States: loading/empty/error+retry exist on home (retry calls
  `provider.load()`); search/favorites/category have empty states; Settings
  surfaces refresh status/errors. Offline = works from bundled/cache content,
  shown as `محفوظ محلياً` in Settings (no connectivity package added — YAGNI).
- Search: in-memory per keystroke, no network; 5000-entry benchmark ≈ 25ms
  per search on this machine (guarded by `search_performance_test.dart`).
- Startup: single `ContentProvider.load()` reads JSON once (cache → bundle);
  all screens read the in-memory catalog. No `print`/logging of sensitive
  data anywhere (no logging at all).
- Android: core-library desugaring enabled in `build.gradle.kts`
  (`desugar_jdk_libs:2.1.4`) — required by `flutter_local_notifications`;
  manifest declares only `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`.

### Prompt 09 notes (carried forward)

- Reminder is opt-in and explicitly labelled as a convenience, not a
  religious obligation (Arabic UI copy enforces this).
- Scheduling is **inexact only** (`AndroidScheduleMode.inexact`) — no
  `SCHEDULE_EXACT_ALARM` permission; single notification ID so rescheduling
  replaces. Runtime permission requested on toggle (Android 13+), denial is
  reported in the Settings UI and the reminder stays off.
- Android manifest now declares `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`
  (plugin boot receiver re-arms reminders after reboot).
- Notification tap uses the default launcher activity (no deep link), so no
  deep-link target validation was needed.
- **Device delivery not tested** — verified only via unit/widget tests
  (`flutter test`); on-device scheduling requires a manual Android run.
