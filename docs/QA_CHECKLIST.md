# Manual device test checklist

Run this list before every release build. "Device" means a real phone or
emulator with the release-like profile (no debug banner, AAB-installed);
desktop means the Linux `.deb` and Windows MSIX builds. Every Arabic string
below is what the tester should see on screen.

## RTL and layout

- [ ] App opens fully RTL: bottom-nav labels start from the right, back
      arrows in pushed screens point right, list content is right-aligned.
- [ ] No clipped or overflowing text at the narrowest supported width
      (320 dp) on home, categories, reader, search, favorites, settings.
- [ ] Tablet / wide desktop window: the app column stays capped and
      centered; cards do not stretch edge-to-edge.
- [ ] Rotate the phone on every screen: nothing is lost, no overflow
      banners, counter progress intact.

## Font and text

- [ ] System font size at 200% (accessibility settings): home, reader and
      search render without overflow or hidden controls (automated
      coverage: `test/ui/font_scale_test.dart` at 1.5x/2x).
- [ ] Bold text (accessibility "bold text" toggle) does not clip labels.
- [ ] Qur'anic and dua text shows full tashkeel with the bundled Amiri /
      Tajawal fonts — no tofu boxes, no missing marks on a low-end device.
- [ ] Settings → حجم خط المحتوى: stepper changes the live Amiri preview,
      reset restores 20, and the reader A+/A- reflect the same value.

## Theme and motion

- [ ] Settings → المظهر: تلقائي / فاتح / داكن switch without a white flash
      on restart (mode is restored before the first frame).
- [ ] Dark mode: every screen (home, categories, reader, search,
      favorites, settings, dialogs, snackbars) is readable.
- [ ] Reduce-motion (accessibility setting): counter dial, heart toggle
      and page transitions stop animating; nothing becomes unreachable.
- [ ] Contrast spot-check on parchment and dark backgrounds: body text,
      muted text, source lines, gold accents (automated token coverage in
      `test/ui/theme_contrast_test.dart`).

## Screen reader (TalkBack / VoiceOver / NVDA on desktop)

- [ ] Home: greeting, search entry, continue card ("تابع من حيث توقفت"),
      featured cards and category cards are each announced with their
      Arabic text.
- [ ] Reader: title, body and source are read in order; copy/share/font
      buttons announce مشاركة / نسخ / تصغير الخط / تكبير الخط.
- [ ] Counter dial announces اضغط للعد, then the "x من y" progress, then
      اكتمل العد when finished.
- [ ] Favorite hearts announce إضافة إلى المفضلة / إزالة من المفضلة.
- [ ] Settings switches announce their Arabic titles; time rows announce
      the chosen time.
- [ ] Search: typing updates results; the no-results state is announced.

## Content and offline

- [ ] Airplane mode: full cold start works; every category, dua, hadith
      and dhikr opens from the bundled assets.
- [ ] Settings → تحديث المحتوى is the only network action; with the
      placeholder host it fails gracefully with the Arabic error message
      and keeps the local snapshot.
- [ ] Favorites, counter progress and continue-where-you-left-off survive
      a force-stop and relaunch; counter progress resets on a new day.
- [ ] Background the app mid-counter, reopen: progress is intact.
- [ ] Content update (when a real host exists): old favorites resolve,
      removed entries disappear without errors, the "about" version
      matches the manifest.

## Reminders (Android + Windows only)

- [ ] Settings shows التذكيرات with independent صباح / مساء toggles.
- [ ] First enable prompts for notification permission; deny shows the
      Arabic guidance and the toggle stays off.
- [ ] Set both times a minute ahead, background the app: both fire with
      the right body text; tapping one opens the matching adhkar.
- [ ] Reboot the device: reminders still fire (boot receiver).
- [ ] Change the device timezone, relaunch: reminders re-arm for the new
      local time.
- [ ] Linux build: the reminder card is replaced by the "غير مدعوم"
      notice.

## Performance

- [ ] Cold start to interactive home < 2s on a low-end device (emulated
      2 GB RAM profile is fine).
- [ ] Scroll home, a long category and search results: no visible jank;
      girih/ornament layers do not repaint during scroll.
- [ ] Reader with the longest bundled entry at 200% font: no overflow
      (automated) and no dropped frames when toggling the counter.
- [ ] Memory: open 10 entries, switch tabs 20 times — no growth trend in
      the profiler, no OOM on the low-end profile.

## Haptics and audio

- [ ] Counter tap gives a light impact; completion gives a heavier one.
- [ ] Device on silent: no unexpected sounds (the app has none).

## Platforms not in scope

- [ ] iOS/macOS/Web: known scaffolded-only; do not ship store listings
      for them until the checklist above passes there.
