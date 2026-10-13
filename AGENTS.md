# AGENTS.md

## Project

**رفيق المسلم — The Muslim's Companion.** A Flutter app with an **Arabic-only,
RTL** UI (Material 3) for reading categorized Islamic content: duas, hadiths,
and adhkar. Content is bundled as JSON in `assets/data/` and served through a
local repository — **no backend, no database, no login, no analytics, no ads.**

- Package name: `the_muslims_companion`; app id `com.ideas2d.themuslimscompanion`.
- Canonical app name: Arabic **رفيق المسلم**, English **"The Muslim's Companion"**.
- Theme: green/off-white/beige Material 3 in `lib/app/theme/app_theme.dart`
  (`greenPrimary #2E6B34`, `beigeAccent #CBB98A`, `offWhite #FBF9F4`),
  `fontFamily: 'NotoNaskhArabic'` (bundled, OFL).

## Commands

Flutter is **not on the default PATH** — export it first:

```bash
export PATH="$HOME/flutter/bin:$PATH"   # Flutter 3.47.x lives at ~/flutter
```

```bash
flutter pub get
dart format .          # always run before committing Dart changes
flutter analyze        # must be clean
flutter test           # 16 test files; keep green
flutter build apk --debug      # Android smoke build
flutter build appbundle --release
flutter build linux --release   # desktop
flutter build windows --release # desktop
```

## Conventions

- **Arabic-only UI; RTL always.** Use Directionality-aware APIs
  (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end alignment) —
  never hardcode left/right offsets.
- **Never modify displayed or shared Arabic diacritics.** Content is verbatim
  from the JSON in `assets/data/`.
- **Religious text and attributions are never invented.** Unverified entries
  are clearly labelled and excluded from production until verified. See
  `docs/CONTENT_SCHEMA.md`.
- **No backend / DB / login / analytics / ads** in the MVP.
- **Platform checks use `defaultTargetPlatform`** (from `flutter/foundation.dart`),
  not `dart:io`'s `Platform` (which breaks web). `dart:io` is fine for file IO
  only (`lib/main.dart`, `lib/content/refresh/content_cache.dart`).
- Remote content base URL `kContentBaseUrl` (`lib/main.dart`) is a **placeholder**
  (`content.example.com`) — real host goes in before release; see
  `docs/CONTENT_PUBLISHING.md`.

## Testing

- Mock `SharedPreferences` in every store test:
  `SharedPreferences.setMockInitialValues({})`.
- Load bundled JSON in UI tests via the `fixtureLoader` helper from
  `test/ui/shell_test.dart`.
- Tap widgets by their **Arabic** labels in widget tests.
- Notification scheduling is **Android + Windows only**; the Linux plugin lacks
  `zonedSchedule`, so `supportsScheduling` is false there and the reminder card
  is hidden (`lib/ui/screens/settings_screen.dart`).

## Platforms

| Platform | Status |
|----------|--------|
| Android  | Primary target; release-built as AAB |
| Linux    | Desktop; release-built as `.deb` (reminders hidden) |
| Windows  | Desktop; release-built as MSIX (reminders work) |
| iOS / macOS | Scaffolded only; no Darwin notification init, not built in CI |
| Web | Scaffolded only; `path_provider` / `flutter_timezone` unsupported |

CI: `.github/workflows/ci.yml` (analyze + test + Linux debug).
Release: `.github/workflows/release.yml` (tag `v*` → Android AAB, Linux deb,
Windows MSIX; publish gated on Android success, Windows is experimental).

## Packaging

- `packaging/deb/` — Debian build script, `.desktop`, metainfo.
- `snap/snapcraft.yaml` — Snap (strict, GNOME extension).
- `flatpak/` — Flatpak manifest + wrapper.
- `pubspec.yaml` `msix_config:` — Windows MSIX settings.

## Legal

`LICENSE` (MIT), `NOTICE`, `PRIVACY_POLICY.md`, `SECURITY.md`, `store/listing.md`.

<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use this to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->
