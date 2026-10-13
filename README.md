# رفيق المسلم — The Muslim's Companion

A Flutter Android app (Arabic-only UI, RTL) providing categorized Islamic
content: duas, hadiths, and adhkar — with search, favorites, copy/share, an
adhkar counter, adjustable font size, and optional daily reminders.

Content is bundled with the app as JSON (`assets/data/`); remote content
updates and an offline cache are planned in a later milestone.

## Setup

1. Install the Flutter SDK (stable channel, 3.47+ tested). Example for Linux:

   ```bash
   # ~/flutter is used throughout this project; adapt if you install elsewhere.
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz
   tar xf flutter_linux_3.47.7-stable.tar.xz   # extracts to ~/flutter
   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. Verify the toolchain:

   ```bash
   flutter doctor
   ```

## Run

```bash
flutter pub get
flutter run            # on a connected device/emulator
```

## Checks

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug   # requires the Android toolchain from flutter doctor
```

## Project layout (feature-oriented, grows per milestone)

```
lib/
  main.dart            # app shell: Arabic locale, RTL, Material 3 theme wiring
  app/theme/           # green/off-white/beige Material 3 theme constants
assets/data/           # bundled JSON content (added in the content milestone)
docs/                  # implementation plan, content schema (later milestones)
```

## Conventions

- Arabic-only UI; RTL always. Use Directionality-aware APIs
  (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end alignment) —
  do not hardcode left/right offsets.
- Never modify displayed/shared Arabic diacritics. Content verbatim from JSON.
- No backend, no database, no login, no analytics, no ads in the MVP.
- Religious text and attributions are never invented; unverified placeholders
  are clearly labelled and excluded from production until verified.
