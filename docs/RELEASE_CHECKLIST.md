# Release Checklist — رفيق المسلم (TheMuslimsCompanion)

Status: prepared during Prompt 11 (2026-10-13). **Nothing has been signed,
uploaded, or published.** Store approval is not claimed anywhere in this doc.

## 1. Build commands

```bash
export PATH="$HOME/flutter/bin:$PATH"

dart format lib test
flutter analyze                 # must be "No issues found" (exit 0)
flutter test                    # must be 120/120 passing (exit 0)
flutter build appbundle --release
```

Expected artifact:

```
build/app/outputs/bundle/release/app-release.aab
```

Debug smoke build (no signing setup needed):

```bash
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

> A `.aab` produced **without** a release keystore (see §2) is signed with the
> **debug** key and is only usable for local testing — never upload it to Play.

## 2. Signing configuration (keep secrets out of git)

Keystores and passwords must never be committed. `.gitignore` already blocks
`android/key.properties`, `*.jks`, and `*.keystore`.

One-time setup on the release machine only:

```bash
keytool -genkey -v -keystore ~/keystores/muslim-companion.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

Create `android/key.properties` (git-ignored, machine-local):

```properties
storePassword=<from your password manager>
keyPassword=<from your password manager>
keyAlias=release
storeFile=/home/<you>/keystores/muslim-companion.jks
```

Wire it in `android/app/build.gradle.kts` (only when the file exists):

```kotlin
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

Rules:

- Never commit `key.properties`, the keystore, or any password.
- Back up the keystore + passwords offline (losing them means losing the
  ability to update the app).
- Prefer Play App Signing: upload the `.aab`, let Google hold the app-signing
  key; keep only the upload key locally.

## 3. Identity & configuration (current state)

| Item | Value | Status |
|------|-------|--------|
| applicationId / namespace | `com.ideas2d.themuslimscompanion` | ✅ set (Prompt 11) |
| Launcher label | `رفيق المسلم` | ✅ set |
| versionName / versionCode | `1.0.0` / `1` (pubspec `1.0.0+1`) | ✅ |
| Launcher icon | default Flutter template icon | ⚠️ blocker: replace with real branding |
| Permissions | `INTERNET` (content refresh), `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` (notification vibration, added by the notifications plugin, normal-level) | ✅ minimal; no exact-alarm, no storage, no ads/Analytics |
| Release signing | artifact signed with **debug key** (verified via `keytool -printcert`) — not publishable | ⚠️ blocker: see §2 |
| `kContentBaseUrl` in `lib/main.dart` | `https://content.example.com/v1` placeholder | ⚠️ blocker: replace with the real content host before enabling updates in production (see `docs/CONTENT_PUBLISHING.md`). Reserved `.example.com` can never serve real content, so the placeholder cannot be mistaken for a live endpoint. |
| Content review status | every entry carries `verified` + `placeholder` flags; **release builds exclude all `!verified` or `placeholder` entries** (`LocalContentRepository`, `kReleaseMode`) | ✅ blocking enforced in code; per-entry scholarly verification remains the content owner's ongoing task |

## 4. Privacy

- No accounts, no analytics, no ads, no third-party SDKs beyond
  `flutter_local_notifications` / `timezone` (local-only) and `http` +
  `path_provider` (content refresh).
- No data leaves the device except optional HTTPS fetches of the public
  content JSON (no user data in requests).
- Persisted locally: favorites, counters, reminder time/enabled — never
  uploaded anywhere.

## 5. Automated verification (run before every release)

- [ ] `dart format` → 0 changes
- [ ] `flutter analyze` → No issues found
- [ ] `flutter test` → all passing (121 as of Prompt 11)
- [ ] `flutter build appbundle --release` → artifact exists at §1 path
      (last verified 2026-10-13: `app-release.aab`, 53.5 MB)

## 6. Manual device tests (before store submission)

- [ ] Cold start **in airplane mode** shows content (bundled) without errors
- [ ] Categories → reader: text renders RTL, source line shown, counter works
- [ ] Search with tashkeel/alef variants finds entries
- [ ] Favorites: add from reader, appear in tab, survive app restart
- [ ] Counter: increment/reset/target persist across restart
- [ ] Content refresh: succeeds on real host, fails gracefully offline
      (Settings shows error, content unchanged)
- [ ] Reminder: toggle on → permission dialog → notification arrives within
      the system inexact window at the chosen time; toggle off stops it;
      reboot keeps it (boot receiver); tap opens the app
- [ ] Release build shows **no** placeholder entries ("غير موثّق" badge absent)
- [ ] Large font (system font size ×2) — no clipped text
- [ ] TalkBack: counter, cards, switch, and icon buttons are announced
- [ ] `adb shell dumpsys package com.ideas2d.themuslimscompanion` shows only
      the three expected permissions

## 7. Store submission blockers (open)

1. Real launcher icon (template icon still in place).
2. Release keystore + `key.properties` on the build machine (§2).
3. Real `kContentBaseUrl` host before shipping content updates.
4. Play Console account/developer identity (outside this repo).
5. On-device verification of notifications and refresh — **not testable in
   CI; nothing in this repo claims device delivery was tested.**
