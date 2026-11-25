# Performance

> **No measurements have been taken yet.** The app has not been run in profile mode on a device. Nothing below is a benchmark; it lists design choices made for performance. Record real measurements in the table at the end.

## Strategies in the code

| Area | What the code does |
|---|---|
| Rebuild scope | Riverpod providers watched at screen level; ephemeral state (forms, drag offset) local to small `StatefulWidget`s. Send button rebuilds alone through `ListenableBuilder` on the text controller. |
| `const` | Enforced by lints (`prefer_const_constructors`, `prefer_const_declarations`). |
| Lists | Matches: `ListView.separated` (lazy). Chat: `ListView.builder`, `reverse: true`. |
| Data volume | Fixed limits: 50 candidates per load, 100 messages per chat. Candidate and seen-likes queries run in parallel (`Future.wait`). |
| Duplicate requests | Swipe buttons act on the top card only and it is removed optimistically, so repeated taps hit different cards. Primary buttons disable while loading. |
| Images | Only the bundled splash logo (decoded at display size, ~1.1 MB asset). Avatars are initials — no network images. |
| Fonts | System fonts only; no bundled font files. |
| Dependencies | 9 direct runtime packages, all first-party Flutter/Firebase or Riverpod/go_router. |
| Animations | Transforms/opacity only (swipe card 250 ms, splash ~2.2 s); no shadows or blurs; one radial gradient for the splash glow. Reduced motion honored. |
| Memory / lifecycle | `autoDispose` providers for discover, matches and messages; controllers disposed; Firestore listeners cancelled with providers. |
| Startup | Only `Firebase.initializeApp` before `runApp`; everything else is lazy (providers are created on first watch). Native launch screen is black (no bitmap to decode). |
| Splash animation | Built-in transitions only (`FadeTransition`, `ScaleTransition`, `SlideTransition`) — no Lottie/Rive. Logo decoded once at display size via `ResizeImage` (not 1536 px) and precached. One radial gradient for the glow. Progress driven by a ticker capped at ~34 ms per frame so startup stalls don't skip stages. Overlay removed from the tree after the reveal. |
| Isolates | Not used — no CPU-heavy work (ranking ≤ 50 items is trivial). |
| `RepaintBoundary` | Not added; no profiling evidence that it is needed. |
| Cache | Firestore offline persistence (SDK default). |

## How to measure

```bash
flutter run --profile
```

Then open DevTools (Performance, Memory, CPU profiler). Suggested checks:

1. Cold start to first frame of Discover.
2. Frame times while dragging the swipe card and scrolling a 100-message chat (target: no frames over budget at the device refresh rate).
3. Memory after opening/closing 10 chats (should return to baseline).
4. Release size:

```bash
flutter build apk --release --analyze-size --target-platform android-arm64
```

## Measurements

| Date | Device | OS | Flutter | Mode | Tool | Method | Result |
|---|---|---|---|---|---|---|---|
| 2026-11-20 | Pixel 8 API 36 emulator (software rendering) | Android 16 | 3.50.1 | debug | `adb screenrecord` + ffmpeg frame analysis | Cold start after `am force-stop`, 10 fps frame extraction, mean brightness per frame | Black from launch until the first Flutter frame (~5 s in debug on this emulator — not representative of release); no white frame; logo fade-in, growth and reveal progressed gradually over ~5.5 s because the emulator rendered slowly; app revealed once startup resolved. Frame rate on real devices not measured yet. |
