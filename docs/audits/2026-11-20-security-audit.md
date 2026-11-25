# Security Audit — 2026-11-20

**Scope:** `firestore.rules` (as deployed to `skill-suap`), Dart code in `lib/`, Android/iOS configuration, build/release setup, local tooling in `tool/`, dependencies.
**Method:** static review of every file in scope, dependency advisory check (`flutter pub get`), secret scan, and behavior observed in the manual end-to-end run on the emulator. Rules were **not** attacked live and not run in the Firebase Emulator. Firebase Console settings (App Check, API key restrictions, Auth policies, Storage) were **not** visible to the audit and are listed as items to verify.
**Status:** findings recorded first, without changes. Remediation progress is tracked below.

## Remediation status (updated 2026-11-20)

| ID | Status | Evidence |
|---|---|---|
| M1 | **Fixed** — likes readable only by their author; client no longer reads the other person's like | rules tests `[M1]`; repository tests |
| M2 | **Fixed** — match create/update keys exact; no names stored (read from profiles); preview must mirror a message created in the same batch | rules tests `[M2]` |
| M3 | **Fixed** — skills limited to the catalog on the server; unknown ids dropped on read | rules tests `[M3]`; repository test |
| M4 | **Partly fixed** — user listing requires `limit <= 50`; App Check and API key restrictions still open | rules test `[M4]` |
| L1 | **Fixed** — all timestamps must equal `request.time` | rules tests `[L1]` |
| L4 | **Fixed** — 40 rules tests on the Firestore Emulator | `firestore_rules_test/` |
| H1 | **Fixed** — consent (18+, terms) enforced on profile creation; unmatch; private blocks that prevent matches and messages; write-only reports with moderation in the console | rules tests `[H1]` (26), Dart tests `[H1]` (13), device check |
| H2, M5, M6, L2, L3, L5, L6 | Open | — |

Deployed to `skill-suap` on 2026-11-20 and re-checked on the Android emulator (existing match, chat send, profile save: no denials).

## Summary

| Severity | Count |
|---|---|
| High | 2 |
| Medium | 6 |
| Low | 6 |

No critical issue found: authentication is required everywhere, only owners write their profile, matches require both likes (verified live), chats are members-only and immutable, no secrets beyond public Firebase identifiers, no logging, HTTPS only.

## High

### H1 — No safety controls in a stranger-to-stranger chat
**Where:** product / `features/matches`. **What:** no block, unmatch, report, age requirement or terms of use. Once matched, a user can message the other indefinitely and the victim cannot stop it (match and message deletes are denied by rules).
**Impact:** harassment with no recourse; store rejection (Google Play/App Store require user-generated-content reporting and blocking).
**Fix:** `blocks/{uid}_{otherUid}` + rules denying message create when blocked; unmatch (member-only delete or `status: closed`); report collection; age/terms acceptance at sign-up.

### H2 — Unlimited writes on the free quota (abuse / denial of service)
**Where:** `firestore.rules` (likes, messages, users), no App Check. **What:** any account — or a script using the public config — can create unlimited likes, messages and profile updates. On the Spark plan the daily free quota (≈20k writes) can be exhausted by one user, taking the app down for everyone until the next day.
**Fix:** enable **App Check** (Play Integrity / App Attest) and enforce it for Firestore and Auth; per-user rate limit in rules (e.g., message `createdAt == request.time` plus a per-user `lastWriteAt` doc checked with `getAfter`); budget/usage alerts.

## Medium

### M1 — Users can see who liked or skipped them
**Where:** `likes` `allow get` (line 43). **What:** the rule lets the target read `likes/{other}_{me}`. Any user can iterate other uids (all readable from `users`) and learn who liked them **and who skipped them** (`liked: false`).
**Fix:** allow `get` only to the author (`resource == null || resource.data.from == request.auth.uid`). The client should then attempt the match `create` directly (the rule already checks both likes) and treat `permission-denied` as "no match yet" instead of reading the reverse like.

### M2 — Match documents accept unvalidated, client-written fields
**Where:** `matches` `allow create` (lines 60–66) and `update` (69–72). **What:** create does not restrict keys or validate `names`, `lastMessage`, `createdAt`; update accepts any `lastMessage` value. A matched user can set the other person's display name in the match (shown in their Matches list and chat header) to anything — impersonation/offensive content — and write an arbitrary-size preview not tied to a real message.
**Fix:** `keys().hasOnly([...])`; `names[u] == get(/users/u).data.name` for both ids; `lastMessage == null` on create; on update `lastMessage is string && size() <= 2000`; timestamps `== request.time`.

### M3 — Skill lists accept arbitrary strings
**Where:** `users` rule (lines 34–37); `Skills.label` shows unknown ids verbatim. **What:** `teach`/`learn` items are not checked against the catalog or for type/length; any text can be injected and is rendered as tags on other users' cards (spam/offensive content, oversized documents up to 1 MiB).
**Fix:** `request.resource.data.teach.hasOnly([<20 catalog ids>])` (same for `learn`); in the app, hide unknown ids instead of rendering them.

### M4 — Whole user base can be scraped
**Where:** `users` `allow read: if signedIn()`; no App Check; Firebase API keys (public by design) not confirmed as restricted. **What:** any account can list every profile without a limit.
**Fix:** split `get`/`list` and require `request.query.limit <= 50` on list; App Check (H2); in Google Cloud Console restrict the Android key to package `com.skillswap.skill_swap` + SHA-1/SHA-256 and the iOS key to bundle `com.skillswap.skillSwap`.

### M5 — Release build is signed with the debug key and not obfuscated
**Where:** `android/app/build.gradle.kts` line 39. **What:** template default. A release APK signed with the public debug key can be replaced by anyone; Dart code not obfuscated.
**Fix:** upload keystore outside the repo + `key.properties` (already git-ignored); build with `--obfuscate --split-debug-info`. Requires your approval to create signing keys.

### M6 — No account deletion or data retention (LGPD)
**Where:** product. **What:** users cannot delete their account and data; deleting `users/{uid}` (allowed by rules) leaves likes, matches, messages and the Auth account behind. Brazilian LGPD (art. 18) grants deletion rights; stores require in-app deletion; no privacy policy exists.
**Fix:** in-app "delete account" (re-auth → delete Auth user → Cloud Function cleans Firestore); privacy policy; retention rule.

## Low

| ID | Finding | Fix |
|---|---|---|
| L1 | Client-chosen timestamps (`createdAt`, `lastMessageAt`, `updatedAt`) — message order and dates can be forged. | Require `== request.time` in rules. |
| L2 | Weak account policy: password ≥ 6 chars, no email verification (email squatting, throwaway accounts), no password reset. | Firebase Auth password policy (≥ 8, mixed), `sendEmailVerification`, reset flow. |
| L3 | `android:allowBackup` defaults to true — Firebase Auth session data included in device backups. | `android:allowBackup="false"` or `dataExtractionRules` excluding shared prefs. |
| L4 | Security Rules have no automated tests. | Rules unit tests with the Firestore Emulator for every rule above. |
| L5 | Local tooling: test passwords in plain text (`tool/test_accounts.local.json`, git-ignored); `tool/install_ndk.ps1` does not verify the archive checksum; scripts run with `-ExecutionPolicy Bypass` (process scope only). | Delete the test accounts/file when done; verify SHA-1 from Google's repository manifest; sign scripts or run via `pwsh`. |
| L6 | `profile.dart` stores only the uid as document id and is world-readable to signed-in users — acceptable, but `updatedAt` reveals activity times to everyone. | Drop `updatedAt` from the public doc or move it to a private subcollection. |

## To verify in the Firebase / Google Cloud console (not visible to this audit)

1. App Check status (expected: not enabled).
2. API key restrictions (Android/iOS) in Google Cloud → Credentials.
3. Authentication → Settings: email enumeration protection on; password policy; authorized domains.
4. Storage: if enabled, its rules must deny all (the app does not use Storage).
5. Project members (IAM) and 2-step verification on the owning Google account.
6. Usage/budget alerts.

## What is already done well

- Server-side authorization for every collection; default deny for anything not matched.
- Mutual-like invariant enforced by rules (observed: one-sided like produced no match; mutual like created it).
- Messages: members only, sender must be the caller, 1–2000 chars, immutable.
- No secrets in code beyond public Firebase identifiers; signing files and local credentials git-ignored; not a git repo yet (nothing published).
- No logging; generic auth errors (no account enumeration in the UI); plain-text rendering only (no HTML/link injection); no deep links.
- Android: only `INTERNET` permission, no cleartext traffic (API 28+ default); iOS: default ATS, no exceptions.
- Dependencies current; `pub get` reports no advisories, retracted or discontinued packages.
