# Claude Code Prompt Pack — رفيق المسلم

This pack is designed to be run **one prompt at a time** with Claude Code. Each prompt asks Claude to inspect the existing project, implement one milestone, run checks, and report what changed before you continue.

## How to use

1. Open a terminal in the folder where you want the app.
2. Create/open the Flutter project.
3. Start Claude Code from the project root.
4. Copy **Prompt 00** first, then send prompts 01, 02, etc. one by one.
5. Review the changes and test the app after each milestone. Do not send the next prompt until the current one is complete.

If you want Claude Code to work from this file, tell it: `Read CLAUDE_CODE_PROMPTS.md and execute only Prompt 00. Do not execute later prompts.`

## Project decisions

- App name: **رفيق المسلم**
- Flutter + Dart, Android first
- Arabic-only UI with RTL layout
- Green, white, and warm beige design
- Content-driven UI from JSON
- Hybrid content strategy: bundled JSON first, optional remote JSON updates, offline cache
- Features: categories with icons, search, favorites, copy/share, adhkar counter, daily notifications, adjustable font size
- No login, backend database, analytics, ads, or Firebase in the MVP unless explicitly requested later
- Islamic text and attributions must not be invented. Mark unverified content clearly and use placeholders until verified.

---

## Prompt 00 — Inspect environment and plan only

```text
You are working on my Flutter Android app named رفيق المسلم.

Before changing anything:
1. Inspect the current directory, Flutter/Dart versions, project structure, git status, and existing tests.
2. If this is not a Flutter project, tell me and propose the exact command to create it; do not create a nested project without asking.
3. If it is already a Flutter project, identify what exists and what is missing.
4. Create or update a concise implementation plan in docs/IMPLEMENTATION_PLAN.md.
5. Do not implement features yet and do not overwrite user files.
6. Run only safe diagnostic commands and report the results.

Architecture goals:
- Flutter/Dart, Android first
- Arabic RTL interface
- Green, white, beige Material 3 design
- Bundled JSON as the initial source of truth
- Remote JSON updates and offline cache later
- Categories, search, favorites, copy/share, adhkar counter, notifications, adjustable text size
- No backend/database/login for the MVP
- Do not invent Quranic verses, hadiths, sources, authenticity grades, or prescribed repetition counts.

At the end, report:
- Environment and project status
- Files created/changed
- Any blockers
- The exact next action I should take

Do not execute any other prompt in this file.
```

## Prompt 01 — Establish project conventions and dependencies

```text
Implement only Milestone 1: project foundation for رفيق المسلم.

First read docs/IMPLEMENTATION_PLAN.md and inspect the project. Preserve existing work.

Tasks:
1. Ensure the project builds as a Flutter app. Do not create a nested Flutter project.
2. Add only the dependencies needed now: provider, shared_preferences, share_plus, and flutter_localizations from the Flutter SDK. Add http and path_provider only if you implement a minimal repository/cache abstraction in this milestone; otherwise defer them.
3. Configure Arabic locale support and a Material 3 theme using deep green, off-white, and restrained beige/gold accents.
4. Configure RTL for the Arabic app in a maintainable way. Prefer Directionality-aware layout APIs (EdgeInsetsDirectional, AlignmentDirectional, etc.). Do not hardcode left/right unnecessarily.
5. Create a clean feature-oriented lib/ structure, but avoid empty files and unnecessary abstraction.
6. Add assets/data/ and register it in pubspec.yaml.
7. Add a README.md with setup and run commands.
8. Do not add notifications yet.
9. Run dart format, flutter analyze, and flutter test where applicable. Fix issues introduced by your changes.

Do not implement the full UI or remote fetching yet. Report changed files, dependencies, commands run, and any unresolved issues.
```

## Prompt 02 — Define JSON schemas and safe sample data

```text
Implement only the content models and local JSON data for رفيق المسلم.

Inspect the current project and preserve existing work.

Create:
- assets/data/manifest.json
- assets/data/categories.json
- assets/data/duas.json
- assets/data/hadiths.json
- assets/data/adhkar.json
- Dart model classes for categories, entries, sources, and manifest metadata as appropriate.

Requirements:
1. Use UTF-8 Arabic text.
2. Categories need stable id, Arabic title, subtitle, icon key, content file, sort order, and enabled flag.
3. Entries need stable id, categoryId (derived from category when parsing is reasonable), title, text, optional source/reference/authenticity metadata, optional repeatCount, tags, and sort order.
4. Use schemaVersion separately from contentVersion.
5. Validate required fields and reject duplicate IDs and invalid repeat counts.
6. Keep favorite state out of remote content.
7. Do not fabricate religious quotations or claim a source/authenticity without verification. Use clearly labelled schema/demo placeholders or a tiny set of well-known examples only when the wording and attribution can be verified. Mark placeholders so they cannot be mistaken for verified content.
8. Keep JSON structures consistent across files and document the schema in docs/CONTENT_SCHEMA.md.
9. Register the assets in pubspec.yaml.
10. Add unit tests for parsing, missing required fields, duplicate IDs, and optional fields.
11. Run dart format, flutter analyze, and flutter test.

Do not build screens in this prompt. Report the schema and tests.
```

## Prompt 03 — Local content repository

```text
Implement only the local content repository for رفيق المسلم.

Requirements:
1. Load bundled JSON through Flutter assets.
2. Expose typed methods for loading categories, loading entries by category, and loading all entries.
3. Sort categories and entries by sortOrder.
4. Validate category file names and JSON structure. Do not allow arbitrary file paths from untrusted JSON.
5. Handle errors with typed exceptions or clear error results. Do not silently return empty data when parsing fails.
6. Keep UI widgets independent of raw JSON maps.
7. Add tests for successful loading, unknown categories, malformed JSON, and duplicate IDs where practical.
8. Do not implement remote refresh in this prompt.
9. Run dart format, flutter analyze, and flutter test.

Inspect existing models and reuse them instead of duplicating classes. Report how to call the repository and list the tests run.
```

## Prompt 04 — App shell, theme, navigation, and home screen

```text
Implement the first functional UI for رفيق المسلم using the existing models and local repository.

Design:
- Arabic RTL
- Material 3
- Deep Islamic green, off-white, restrained beige/gold
- Clean, calm, readable, accessible
- Avoid excessive gradients, heavy ornament, and crowded cards
- Use icons mapped from safe known icon keys, with a fallback icon for unknown keys
- Use responsive layouts and readable touch targets

Screens/navigation:
1. Home screen with app title, greeting, search entry point, featured-content area only if there is valid content, category cards, and bottom navigation.
2. Categories screen.
3. Favorites screen placeholder with a clear empty state if favorites are not yet wired.
4. Settings screen placeholder.
5. Category detail/list screen that loads entries from the local repository.

Requirements:
- Generate category cards dynamically from JSON; do not hardcode category names in the UI.
- Support empty/loading/error states.
- Use Directionality-aware padding/alignment.
- Keep widgets reusable and files reasonably small.
- Do not add remote networking or notifications yet.
- Add widget tests for RTL, category rendering, and empty/error states where practical.
- Run dart format, flutter analyze, and flutter test.

Do not claim the app was run on an emulator unless you actually ran it. Report exact commands and results.
```

## Prompt 05 — Reader screen, text settings, copy, and share

```text
Implement the Islamic content reader and content actions.

Requirements:
1. Tapping an entry opens a reader screen.
2. Display Arabic text with comfortable line height, clear title, optional verified source/reference, and a readable maximum line width.
3. Add adjustable font size, with a sensible default and minimum/maximum bounds.
4. Add copy-to-clipboard and share actions. Share title, text, source/reference if present, and a short app attribution.
5. Give clear user feedback after copying or sharing where appropriate.
6. Preserve Arabic text exactly; do not modify diacritics or punctuation in the displayed/shared text.
7. Do not show unverified source claims as facts. Hide empty source fields.
8. Add widget/unit tests for font size bounds and action message formatting where practical.
9. Run dart format, flutter analyze, and flutter test.

Use the installed share_plus API version; check package code/docs available in the project rather than guessing deprecated methods. Do not implement favorites or counters in this prompt.
```

## Prompt 06 — Search, Arabic normalization, and favorites

```text
Implement search and persistent favorites for رفيق المسلم.

Search:
1. Search across all currently loaded entries by title, body text, and tags.
2. Search locally in memory; do not send a request for every keystroke.
3. Debounce only if useful; keep behavior responsive.
4. Add optional Arabic normalization for search only, such as removing tashkeel and normalizing common alef variants. Never change stored or displayed text.
5. Include empty query, no results, and error states.

Favorites:
1. Persist stable entry IDs locally using shared_preferences or the project's existing persistence service.
2. Favorites screen resolves IDs against the current content snapshot and handles stale IDs safely.
3. Toggling favorite updates the UI immediately and persists the change.
4. Do not store favorite flags in the JSON content.
5. Add tests for Arabic search normalization, matching title/body/tags, favorites persistence logic, and stale IDs where practical.
6. Run dart format, flutter analyze, and flutter test.

Keep the existing architecture and screens. Report any limitations.
```

## Prompt 07 — Adhkar repetition counter

```text
Implement a repetition counter on entries that support it.

Requirements:
1. Show a counter only where repeatCount is supplied and validated, or allow a separate user-defined target. Never invent a religiously prescribed count.
2. Display current progress, target, increment button, and reset action.
3. Use a large, accessible tap target suitable for one-handed use.
4. Persist current session progress locally and restore it appropriately.
5. Define the semantics of reset and target completion clearly.
6. Prevent negative counts and handle target changes safely.
7. Add tests for increment, reset, persistence, and target completion.
8. Run dart format, flutter analyze, and flutter test.

Keep the interface calm and consistent with the green theme. Do not add sounds or vibration unless explicitly requested.
```

## Prompt 08 — Hybrid JSON updates and offline cache

```text
Implement production-minded hybrid content updates for رفيق المسلم. This is a high-risk data-integrity milestone: inspect the existing repository and tests before changing code.

Goals:
- Bundled JSON works on first launch.
- A previously validated local snapshot is used offline.
- Remote JSON can be refreshed from a configurable HTTPS base URL.
- Failed updates never break reading or destroy the last valid snapshot.

Requirements:
1. Add a manifest with schemaVersion, contentVersion, updatedAt, and a list of content files.
2. Compare remote and local content versions; skip downloads when unchanged.
3. Enforce HTTPS in production and a fixed trusted host/base URL. Do not allow a downloaded manifest to redirect the app to arbitrary hosts or local/private IPs.
4. Use request timeouts, response-size limits, status checks, UTF-8 decoding, and JSON/schema validation.
5. Validate every file and cross-reference before activation: unique IDs, valid category IDs, allowed filenames, and sensible field bounds.
6. Download to a staging location. Activate the complete snapshot only after every required file passes validation. Use a robust rollback strategy so partial downloads never replace a valid snapshot.
7. Persist the active content version and last successful refresh time.
8. On any failure, retain the last valid snapshot and keep the app usable offline.
9. Expose refresh status to the UI without intrusive repeated error dialogs.
10. Add tests for unchanged version, successful update, timeout, invalid JSON, duplicate IDs, invalid category references, partial download, and rollback.
11. Document how to host and publish a content release in docs/CONTENT_PUBLISHING.md.
12. Run dart format, flutter analyze, and flutter test.

Do not claim cryptographic integrity or authenticity unless you implement and verify it. Do not use a remote JSON field as an arbitrary URL. Report security assumptions and test results.
```

## Prompt 09 — Daily local notifications

```text
Implement optional daily local reminders for رفيق المسلم using flutter_local_notifications and timezone support.

Requirements:
1. A settings screen allows enabling/disabling the reminder and choosing a local time.
2. Use a daily reminder message in Arabic, such as "حان وقت أذكار الصباح", without presenting notifications as religious obligations.
3. Request runtime notification permission on supported Android versions and explain denial gracefully.
4. Initialize timezone handling correctly for the device's local timezone.
5. Use inexact scheduling unless exact alarms are explicitly justified. Do not request exact-alarm permissions by default.
6. Persist reminder enabled state and chosen time.
7. Rescheduling a reminder should replace the previous scheduled reminder rather than creating duplicates.
8. Tapping the notification should open the app safely. If deep linking to a category is implemented, validate the target.
9. Handle permission denied, notifications disabled, and initialization errors.
10. Update Android configuration as required by the installed package version.
11. Add tests for time parsing, scheduling configuration, and settings persistence where practical.
12. Run dart format, flutter analyze, and flutter test.

Check the actual installed plugin API and its Android setup instructions. Do not claim device notification delivery was tested unless it was.
```

## Prompt 10 — Accessibility, polish, and quality checks

```text
Perform a quality and accessibility pass on the existing رفيق المسلم app. Do not redesign it from scratch.

Check and improve:
1. Arabic RTL layout and directional spacing.
2. Arabic typography, line height, font scaling, long text wrapping, and source labels.
3. Contrast, touch-target sizes, semantic labels, screen-reader behavior, and keyboard focus where applicable.
4. Loading, empty, offline, error, and retry states.
5. Navigation consistency and preservation of state.
6. Search performance on a moderately large local content set.
7. App startup behavior and avoiding unnecessary repeated JSON reads.
8. Error handling and logs that do not expose sensitive information.
9. Dependency/API deprecations and Android manifest/configuration consistency.
10. Tests for key flows.

Run dart format, flutter analyze, flutter test, and flutter build apk --debug if the Android toolchain is available. Fix all issues introduced by the project where possible. Report any pre-existing failures separately. Do not claim a command passed unless its output confirms success.
```

## Prompt 11 — Release readiness

```text
Prepare رفيق المسلم for an Android release candidate. Do not publish or upload anything.

Tasks:
1. Inspect app name, Android applicationId, versionName/versionCode, launcher icon, splash screen, permissions, and release configuration.
2. Ensure no debug-only URLs, placeholder secrets, or test content can be mistaken for production content.
3. Verify that every published religious text and attribution has an explicit review status; block or clearly exclude unverified entries from production content.
4. Confirm offline startup, cache rollback, favorites, search, counters, and notification settings.
5. Review privacy implications. Since the app has no account, avoid adding unnecessary permissions or data collection.
6. Document how to configure signing securely without committing keystores or passwords.
7. Run dart format, flutter analyze, flutter test, and flutter build appbundle --release if the environment permits.
8. Do not commit signing secrets, publish the app, or claim store approval.
9. Create docs/RELEASE_CHECKLIST.md with commands, expected artifacts, and manual device tests.

Report build results, exact artifact path if confirmed, blockers, and remaining manual checks.
```

---

## Suggested execution order

Run these prompts in order:

1. Prompt 00 — Inspect and plan
2. Prompt 01 — Foundation
3. Prompt 02 — JSON schema and models
4. Prompt 03 — Local repository
5. Prompt 04 — UI and navigation
6. Prompt 05 — Reader and share
7. Prompt 06 — Search and favorites
8. Prompt 07 — Counter
9. Prompt 08 — Hybrid updates and offline cache
10. Prompt 09 — Notifications
11. Prompt 10 — Polish and testing
12. Prompt 11 — Release readiness

## Useful instruction if Claude Code starts doing too much

```text
Stop after the current prompt's scope. Do not implement later milestones. First run the relevant checks, fix issues caused by your changes, summarize files changed and tests run, and wait for my next instruction.
```

## Important note

These prompts are an implementation plan, not proof that the application has been built or tested. Review each diff, run the app on an Android emulator/device, and verify religious content before publishing.
