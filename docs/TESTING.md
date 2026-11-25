# Testing

## Strategy

- **Unit**: pure logic (compatibility score, match id, router redirect).
- **Repository**: real repository code against `fake_cloud_firestore` (in-memory Firestore) — exercises queries, writes and match creation without network.
- **Widget**: screens inside a `ProviderScope` with overridden Firebase providers, Portuguese locale, real theme.
- **Integration / rules / performance**: planned (see below).

## Status

| Area | File | Tests | Status |
|---|---|---|---|
| `Compatibility.score` (100 / 50 / 0) | `test/domain_test.dart` | 3 | Implemented, executed, passing |
| `Match.pairId` order independence | `test/domain_test.dart` | 1 | Implemented, executed, passing |
| Navigation redirects (`resolveRedirect`) | `test/domain_test.dart` | 4 | Implemented, executed, passing |
| Candidate query + ranking | `test/repositories_test.dart` | 1 | Implemented, executed, passing |
| Swiped profiles excluded | `test/repositories_test.dart` | 1 | Implemented, executed, passing |
| Skip never attempts a match | `test/repositories_test.dart` | 1 | Implemented, executed, passing |
| Like denied by rules → no match; accepted → match without names; concurrent creation → match; other errors surface as `Failure` | `test/repositories_test.dart` | 4 | Implemented, executed, passing (rules answer simulated with `mock_exceptions`) |
| Send message (trim, ignore blank, preview linked to message id) | `test/repositories_test.dart` | 1 | Implemented, executed, passing |
| Unknown skill ids dropped when reading profiles | `test/repositories_test.dart` | 1 | Implemented, executed, passing |
| [MS-10] server unreachable with cache → cached deck; with nothing cached → NetworkFailure; server too slow → cache; permission error not treated as offline; online empty → real empty deck | `test/repositories_test.dart` | 5 | Implemented, executed, passing |
| [H1] consent stored with the profile; unmatch; legacy status; block (+close, no double close); report (+block +close, details truncated, from Discover); blocked hidden from Discover; closed match is not a match | `test/repositories_test.dart` | 9 | Implemented, executed, passing |
| [H1] redirect: consent gate, consent loading, terms always reachable | `test/domain_test.dart` | 3 | Implemented, executed, passing |
| [H1] profile setup cannot be saved without consent, saves profile + consent when ticked | `test/widgets_test.dart` | 1 | Implemented, executed, passing |
| Sign-in validation messages (pt) | `test/widgets_test.dart` | 1 | Implemented, executed, passing |
| Discover renders card + compatibility, skip empties deck | `test/widgets_test.dart` | 1 | Implemented, executed, passing |

Total Dart: **68 tests** (11 unit, 23 repository, 2 widget, 11 splash, 21 match screen), all passing on Flutter 3.50.1 / Windows (2026-11-20).

### Match screen tests (`test/match_screen_test.dart`)

KnowledgeMatch (exchange / learn / teach / none). Screen: real skills and banner shown, no invented data; header (bell disabled, profile button, logo label); approve records the like and advances without a match when the server refuses; approve accepted shows the match dialog; pass + undo restores the card; undo not offered after approval; save disabled; fast double tap → one decision; drag right approves, short drag snaps back; network failure and permission/expired-session errors keep the card and explain; load failure → retry; empty deck; profiles without skills/connection (no banner); 320 dp + 200% text with long name/bio/many skills (no overflow); Android tap-target and labeled tap-target guidelines. These tests caught a real bug: the ✓/✗ buttons did nothing because a new `GlobalObjectKey` (identity-compared) was created on every call — fixed with a stable key per profile.

Images: profile photos are covered by `test/profile_photo_test.dart` (JPEG header parsing, size/dimension limits, metadata removal, PNG/transparency, invalid files, Firestore round-trip, photo removal, avatar fallback to initials).

### Responsiveness tests (`test/responsive_matrix_test.dart`, `test/adaptive_widgets_test.dart`)

Every route at 11 viewports × text 100/130/200 % (scrolled to the end), a notched phone in landscape, sheets/dialogs/menus (checking where each action leads), sign-in/setup/consent and text-entry screens with the keyboard open, and Flutter's tap-target, label and contrast guidelines. Layout exceptions are collected per route instead of stopping at the first. `adaptive_widgets_test.dart` covers `PersonName`, `ContentWidth` (state kept across the cap, notch insets), `showActionSheet`, `AdaptiveButtonRow`, the bottom bar's shared label scale and the profile header. Note: tests render with the Ahem font (1 em per glyph), wider than Roboto.

### Splash tests (`test/splash_test.dart`)

`isStartupResolved` (5 cases) and `SkillSwapSplashScreen` widget tests: fast startup plays the full intro then reveals once and keeps the app's state; slow startup holds the logo until ready with no extra delay; ready during the intro still plays it; reduced motion is static with a short fade; a 1 s stalled frame does not skip the fade-in; disposing mid-animation leaves no running tickers. Device check: cold-start screen recording (see SCREENS.md).

### Security Rules tests

`firestore_rules_test/rules.test.mjs` — **66 tests** (40 + 26 for H1: consent, unmatch, block, report). A mutation check (removing the closed-match and block conditions from the rules) made the corresponding tests fail, confirming they detect regressions., all passing on the Firestore Emulator (firebase-tools 15.37, `@firebase/rules-unit-testing` 6, 2026-11-20). For each collection: legitimate operations succeed; attacks fail (writing as someone else, forged ids/timestamps, extra fields, non-catalog skills, unbounded user listing, reading likes addressed to you, probing others' matches, creating matches without mutual likes, spoofed names/previews, editing/deleting messages, outsiders reading chats). Findings from the [security audit](audits/2026-11-20-security-audit.md) are tagged `[M1]`…`[L1]` in test names. How to run: [firestore_rules_test/README.md](../firestore_rules_test/README.md).

## Manual end-to-end check (executed)

Run on 2026-11-20 on the Pixel 8 API 36 emulator (Android 16 image, software rendering), debug build, against the real Firebase project `skill-suap` with two fictional accounts (credentials in the git-ignored `tool/test_accounts.local.json`, since replaced by the `test1`…`test5` accounts below). Driven with `tool/flow.ps1` and `tool/adb.ps1`.

| # | Step | Result |
|---|---|---|
| 1 | Sign up account A → redirected to profile setup | Pass |
| 2 | Save profile A (teaches Excel, learns English) → Discover empty state | Pass |
| 3 | Edit profile A (name, bio) → saved, back on Profile with new data | Pass |
| 4 | Sign out → back to sign-in | Pass |
| 5 | Sign up account B, profile (teaches English, learns Excel) → Discover shows A, "100% match", matching tags highlighted | Pass |
| 6 | B taps Interested → deck empty, Matches empty (one-sided like) | Pass |
| 7 | Sign in A → Discover shows B; drag card right → "It's a match!" dialog (match created; accepted by deployed Security Rules) | Pass |
| 8 | Send message → chat opens, own bubble lime with time | Pass |
| 9 | A's Matches shows B with last-message preview | Pass |
| 10 | Sign in B → Matches shows A with preview; open chat, reply → both messages in order | Pass |
| 11 | App locale pt-BR (`cmd locale set-app-locales`) → UI and skill names in Portuguese | Pass |
| 14 | Match screen with demo people: Marina (exchange banner) and Júlia (learn banner) cards; pass → next card; undo → restored; skip last card → "Desfazer último pulo" in the empty state → restored; approve both → "Deu match!" each (they had pre-liked Ana); Matches list shows both. Caio (new account): consent required before saving the profile; one-sided approval → no match (server denied the match write). | Pass |
| 13 | [H1] Legacy account (Bia) sees the consent screen; terms open; after accepting → Discover. Chat menu shows Desfazer match / Bloquear / Denunciar. Report without reason → "Escolha um motivo"; with reason → back to Matches, match gone, no `PERMISSION_DENIED`. Ana (legacy) also gets the consent screen; her Matches list is empty (match closed). | Pass |
| 12 | After deploying the hardened rules: existing match shows the name from the profile; chat send updates the preview; profile save; no `PERMISSION_DENIED` in logcat | Pass |

Not re-run on device after the rules change: creating a *new* match (no third test account). Covered by the rules tests and repository tests.

Not covered: error states (offline, permission denied), large text scale, TalkBack, iOS, physical device.

Automation caveats (emulator, not app): Gboard's "Try out your stylus" tutorial can capture injected text (disable with `adb shell settings put secure stylus_handwriting_enabled 0`); `adb input text` mangles shell characters such as `?` and `!`; wait for the keyboard before typing (`tool/adb.ps1 fill` does and verifies the value).

## Test accounts (fictional, complete profiles)

Created by `tool/seed_test_users.ps1` (re-runnable: creates missing accounts, refreshes profiles and photos, never duplicates the chat). Each one is a normal account created through Firebase Auth and written with its own ID token, so every write passes `firestore.rules` (consent first, then profile). Emails and passwords live only in the git-ignored `tool/test_accounts.local.json` (keys `test1` … `test10`). Photos are illustrated avatars (not real people) drawn by `tool/generate_demo_avatars.ps1` into `tool/demo_avatars/`.

| Key | Person | Email | Teaches | Wants to learn | Already done |
|---|---|---|---|---|---|
| test1 | Lucas Ferreira | teste1@gmail.com | Programming, Python, Guitar | English, Piano, Photography, Design | Matched with Gabriel (3-message chat) |
| test2 | Camila Ribeiro | teste2@gmail.com | English, Spanish, Writing | Programming, Guitar, Design, Cooking | Liked Lucas |
| test3 | Bruno Carvalho | teste3@gmail.com | Photography, Video editing, Photo editing | Python, Public speaking, Marketing, Piano | Liked Lucas |
| test4 | Ana Beatriz Lima | teste4@gmail.com | Design, Drawing, Marketing | Programming, Piano, Photography | — |
| test5 | Gabriel Nunes | teste5@gmail.com | Piano, Math, Cooking | Guitar, Programming, English, Photography | Matched with Lucas |
| test6 | Daniel Moreira | teste6@gmail.com | Public speaking, Writing, Marketing | Programming, English, Excel | — |
| test7 | Larissa Mendes | teste7@gmail.com | English, Physics, Writing | Python, Guitar, Drawing | Liked Lucas |
| test8 | Rafael Almeida | teste8@gmail.com | Photography, Crafts, Excel | Programming, Guitar, English | Liked Lucas |
| test9 | Juliana Martins | teste9@gmail.com | Piano, Chemistry, Cooking | Python, Programming, Spanish | Liked Lucas |
| test10 | Thiago Rocha | teste10@gmail.com | Design, Video editing, Math | Guitar, Python, Public speaking | Liked Lucas |

Suggested walkthrough as Lucas (teste1): Discover shows Camila, Bruno, Ana Beatriz, Daniel, Larissa, Rafael, Juliana and Thiago; liking Camila, Bruno, Larissa, Rafael, Juliana or Thiago creates a match immediately; liking Ana Beatriz does not (she has not liked him); Matches already lists Gabriel with a chat. Every account has a non-empty deck.

The `@gmail.com` addresses are not mailboxes we own: never trigger "Forgot password" for them (the email would go to whoever owns that address). Weak, shared passwords are acceptable only for these throwaway accounts; delete them before any public release (Firebase Console → Authentication, plus their Firestore documents).

Note: PowerShell scripts with accented text must be saved as UTF-8 **with BOM**; Windows PowerShell 5.1 reads BOM-less scripts as ANSI and would store accented names wrongly.

## Planned (not implemented)

- Widget tests: profile form validation, chat send/empty/error, matches list states, match dialog.
- Accessibility: `meetsGuideline(androidTapTargetGuideline)`, `textContrastGuideline`, `labeledTapTargetGuideline` on each screen; 200% text-scale golden checks.
- Integration (`integration_test/`) on a device against the Firebase Emulator: sign-up → setup → swipe → match → chat.
- Performance: profile-mode frame timing for swipe and chat (see [PERFORMANCE.md](PERFORMANCE.md)).
- Regression: add a failing test for every bug fixed.

## Commands

```bash
flutter test
```

```bash
flutter test --coverage
```

Full gate (from the workspace root, `scripts/check.ps1` runs pub get, format check, analyze, test):

```powershell
..\scripts\check.ps1
```

## Approval criteria

A change is mergeable only when `dart format --output=none --set-exit-if-changed .`, `flutter analyze` (zero issues) and `flutter test` all pass, the rules tests pass whenever `firestore.rules` changes, new logic has tests, and no critical/high security finding is open.

## Test helpers

`harness()` in `test/widgets_test.dart` wraps a screen with `ProviderScope(overrides: …)`, `AppTheme.dark()`, `Locale('pt')` and `appLocalizationsDelegates`. Override `firestoreProvider` with `FakeFirebaseFirestore()`, `firebaseAuthProvider` with `MockFirebaseAuth()`, or stream providers with `overrideWith((ref) => Stream.value(...))`.
