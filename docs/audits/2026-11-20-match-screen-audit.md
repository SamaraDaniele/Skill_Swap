# Match Screen — Implementation and Security Audit (2026-11-20)

Scope: the redesigned Match (Discover) screen and everything it touches — `lib/features/discover/*`, `lib/core/widgets/glass.dart`, likes/matches/blocks rules, auth/session behavior, privacy of displayed data. Method: static review against applicable OWASP MASVS v2 controls (AUTH, STORAGE, NETWORK, PLATFORM, CODE, PRIVACY) using MASTG techniques that apply without attacking production (code review, rules unit tests on the local emulator, widget tests with simulated server errors, device check). The app is **not** claimed to be fully secure.

## A. Implementation

| | |
|---|---|
| Created | `lib/core/widgets/glass.dart` (GlassPanel, GlassChip), `lib/features/discover/knowledge_match.dart`, `test/match_screen_test.dart` |
| Modified | `lib/features/discover/discover_screen.dart` (new layout), `swipe_card.dart` (fling, horizontal drag, semantics, undo slide-in), `discover.dart` (`restore`), `lib/core/theme/app_tokens.dart` (`AppAssets.logo`), `lib/core/startup/skill_swap_splash_screen.dart` (uses `AppAssets`), ARB files (new strings), `test/widgets_test.dart` (old Discover test moved) |
| Reused | `DiscoverController`/`DiscoverRepository` swipe and match flow, `SafetyRepository`/report sheet, match dialog, `InitialsAvatar`, `MessageView`/`ErrorView`/`LoadingView`, theme tokens, router |
| Dependencies added | None |
| Not implemented (no data/feature exists — not faked) | Photo (needs Firebase Storage → Blaze plan; owner decision), age, city, verified badge, knowledge level, "save for later", notifications. Bell and star are shown **disabled**. |

## B. Findings

| ID | Severity | Description | Component | Evidence | Impact | Recommendation | Status |
|---|---|---|---|---|---|---|---|
| MS-1 | High (pre-existing H2) | No server-side rate limit / App Check: likes and match attempts are unlimited per account | `firestore.rules`, Firebase project | Rules have no frequency checks; App Check not configured | Quota exhaustion (DoS), scripted mass-liking | App Check enforced on Firestore/Auth; per-user write-rate rule; budget alerts | **Open** |
| MS-2 | Medium | A blocked person can still see the blocker's card in Discover (blocks are private to the blocker, so the blocked side cannot filter them) | `DiscoverRepository.fetchCandidates`, `blocks` rules | Rules test "the blocked person cannot see the block"; query filters only the caller's own blocks | Unwanted visibility; cannot match or message (rules deny) | Server-side discovery (Cloud Function) that excludes both block directions | **Open — mitigated** |
| MS-3 | Medium (pre-existing M6) | No in-app account deletion / privacy policy (LGPD art. 18) | product | — | Data-subject rights, store policy | Account deletion + policy | **Open** |
| MS-4 | Low (pre-existing L3) | `allowBackup` default — Firebase Auth session data in device backups | `AndroidManifest.xml` | attribute absent | Session restore from backup on same Google account | `allowBackup="false"` or `dataExtractionRules` | **Open** |
| MS-5 | Low | Undo restores a skipped card only in memory; the stored `liked: false` remains until the user decides again | `DiscoverController.restore` | code + test "pass, then undo" | Person may stay hidden after an app restart | Documented behavior; optional: allow the author to delete own like | **Accepted** |
| MS-6 | Low (pre-existing L6) | `updatedAt` on public profiles reveals activity time | `users/{uid}` | data model | Minor privacy | Move to private doc | **Open** |
| MS-7 | Info | ✓/✗ buttons did nothing (new `GlobalObjectKey` per call, identity-compared) | `discover_screen.dart` | caught by `approve…`/`pass…` tests | Actions silently ignored | Stable key per profile | **Fixed** (tests pass) |
| MS-9 | Low (UX) | Undo disappeared when the skipped card was the last one (empty state replaced the action bar) | `discover_screen.dart` | found on device; test "skipping the last card can still be undone" | Last skip could not be undone | Empty state offers "Desfazer último pulo" | **Fixed** (test + device) |
| MS-10 | Low (UX) | On a slow network the first deck load can come from Firestore's local cache and show "Ninguém novo" until "Atualizar" | `fetchCandidates` (`get()` falls back to cache when the backend is unreachable) | device: empty first load, cards after refresh | Misleading empty state | Server-first fetch (12 s timeout) with cache fallback; offline with nothing cached → "Sem conexão… Tentar novamente"; permission errors are not treated as offline | **Fixed** (5 repository tests) |
| MS-8 | Info | Header overflowed at 320 dp with 200% text | `_Header` | test "long texts at 320 dp and 200% text" | Accessibility | Brand scales down | **Fixed** (test passes) |

No critical findings.

## Controls verified (with evidence)

| Area | Control | Evidence |
|---|---|---|
| AUTH | Every Discover/like/match/block/report operation requires a signed-in user | Rules: `signedIn()` everywhere; rules tests "signed-out visitors cannot read profiles" |
| AUTH | Protected routes need auth, profile and consent | `resolveRedirect` tests; router unchanged |
| AUTH | Session expiry / revoked access is handled | Widget test "expired session / permission error is reported, no crash" (simulated `unauthenticated`); router returns to sign-in when the auth stream emits null |
| AUTH | No tokens in code or logs | Grep: no `print`/`debugPrint`/`log` in `lib/`; tokens managed by the Firebase SDK (no app-side token storage, so `flutter_secure_storage` is not needed) |
| AUTHZ | Cannot like / match / close / message on behalf of someone else; client ids are not trusted | Rules use `request.auth.uid`; rules tests "a like cannot be written in someone else's name", "an outsider cannot create a match between two others", "messages cannot impersonate…" |
| AUTHZ | Unilateral approval ≠ match | Rules require both likes; rules tests "a match needs both likes"; widget test "approve … without a match when the server refuses" |
| AUTHZ | Blocks respected | Rules tests "a block in either direction prevents a match", "a blocked person cannot message"; Discover hides people you blocked (repository test) |
| API/DB | HTTPS only | Firebase SDKs over TLS; no custom HTTP; Android cleartext disabled by default |
| API/DB | Server-side validation | Exact keys, types, sizes, catalog skills, server timestamps — 66 rules tests |
| API/DB | Duplicate requests / idempotency / races | `SwipeCard.fling` lock (test "fast double tap records a single decision"); deterministic like and match ids; concurrent match creation handled (repository test) |
| API/DB | Unexpected responses | Tolerant parsing (unknown skills dropped — test); errors mapped to human messages (network, permission tests) |
| PRIVACY | Only necessary data shown | Card shows name, bio, skills; no email, phone, location, age |
| IMAGES | Only bundled asset (logo) is displayed; decoded at display size | `ResizeImage`; no network images (grep) |
| DEPENDENCIES | No new packages; `pub get` reports no advisories / retracted / discontinued | `scripts/check.ps1` output |

## C. Validation

| | Result |
|---|---|
| `dart format` / `flutter analyze` | Clean / no issues |
| `flutter test` | **62 passed**, 0 failed (20 new match-screen tests) |
| Rules tests (emulator) | **66 passed**, 0 failed (rules unchanged by this work) |
| Device (Pixel 8 API 36 emulator) | Header, empty state and full card flow with real data: exchange and learn banners, pass → next, undo → restored, undo from the empty state, approve with mutual interest → "Deu match!" (twice), Matches list shows both. Server evidence in logcat: `Write failed at matches/…: PERMISSION_DENIED` when a one-sided approval tried to create a match (rules enforce mutual interest); `PERMISSION_DENIED` on the previous user's listeners right after sign-out (no data after logout). |
| Not executed | iOS; physical device; profile-mode performance; image loading tests (no profile photos exist); live authorization attacks against production (not allowed) |

Residual risks: MS-1 to MS-6 above; rules correctness beyond the tested cases; behavior on low-end physical devices.
