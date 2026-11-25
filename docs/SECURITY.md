# Security

> This document describes the measures in place. The app has **not** been through an independent security audit and must not be considered fully secure.

## Authentication

Firebase Auth email/password. Passwords never pass through app code other than the SDK call; minimum length 6 (client) plus Firebase's own policy. Login errors do not reveal whether an email exists.

## Authorization (server-side, `firestore.rules`)

| Collection | Read | Write |
|---|---|---|
| `users/{uid}` | `get`: any signed-in user; `list`: only queries with `limit <= 50` | owner only; exactly `name, bio, teach, learn, updatedAt`; name 1–40 (not blank), bio ≤ 160; skills only from the 20-id catalog (≤ 20 each); `updatedAt == request.time`; **create requires the consent record** (same batch) |
| `users/{uid}/private/consent` | owner only | create once by the owner: `termsVersion == 1`, `adult == true`, server time; no update/delete |
| `likes/{from}_{to}` | author only (`get` by id prefix, `list` where `from == uid`) — nobody can see who liked or skipped them | author only; exactly `from, to, liked, createdAt`; id `{uid}_{to}`; `to` must be an existing user other than the author; `createdAt == request.time`; no delete |
| `matches/{a}_{b}` | members only (`get` checked from the id, so outsiders cannot even probe existence) | create: caller is a member, ids sorted (`a < b`), id equals the pair, **both likes exist with `liked == true`**, **no block in either direction**, `status == 'active'`, exactly `userIds, status, lastMessage(null), lastMessageId(null), createdAt, lastMessageAt` with server time. Update (active matches only): either close it (`status: 'closed'`, `closedBy == uid`, server time — final, no reopening) or set the preview mirroring a message created by the caller in the same batch (`getAfter`). No delete |
| `matches/{id}/messages` | members only (history stays readable after closing) | create by members of an **active** match not blocked by the other member; `senderId == uid`; text 1–2000 chars; exactly `senderId, text, createdAt`; `createdAt == request.time`; no update/delete |
| `blocks/{blocker}_{blocked}` | blocker only (the blocked person cannot detect it) | create by the blocker; target must exist and differ from the caller; server time; no update/delete (no unblock yet) |
| `reports/{id}` | **nobody** (reviewed by the project team in the Firebase console) | create only: `reporterId == uid`, existing `reportedId` ≠ caller, `reason` from a fixed list, `details` ≤ 500, `matchId` null or a match containing both people, server time |

Rules must be deployed (`firebase deploy --only firestore:rules`); client checks alone are not trusted. The rules are covered by **66 automated tests** against the Firestore Emulator in [`firestore_rules_test/`](../firestore_rules_test/README.md) (attack cases must fail, legitimate cases must pass).

Names shown in Matches and Chat are read from the other person's own profile, never from the match document, so a member cannot spoof them. Skill ids outside the catalog are dropped when reading profiles.

## User safety (H1)

- **Consent:** every new profile is created in one batch with `users/{uid}/private/consent` (18+ self-declaration and acceptance of the terms/community rules, version 1); the server rejects a profile without it. Accounts created earlier see a consent screen before using the app (client gate; the age is self-declared, not verified).
- **Unmatch:** either member closes the match; no new messages are accepted afterwards; it disappears from both Matches lists.
- **Block:** private record that permanently prevents a new match and any message between the two people, and closes the current match. Blocked people are removed from the blocker's Discover deck. They are not told about the block (they may still see the blocker in Discover, but liking has no effect).
- **Report:** reason + optional details, written to `reports` (write-only for users) together with a block and the match closing, in one batch. **Moderation process:** the project team reviews Firebase Console → Firestore → `reports` and can disable accounts in Authentication. There is no automated moderation.

## Community (ADR 0005)

- **Authorization in the rules:** only signed-in members read posts; only the author creates, edits (text/type/skills/tags) or deletes a post; images can only be created in the post's own batch (no orphans, no additions later), must be JPEG ≤ 300 KiB and ≤ 1440 px; likes use the member's uid as id (no duplicates); comments allow one reply level; follows cannot target yourself or someone in a block relation; saved posts and notifications are private to their owner.
- **Anti-spam:** a post or comment is accepted only together with a `rateLimits/{uid}` stamp that the rules refuse within 30 s (posts) / 3 s (comments) of the previous one.
- **Notifications cannot be forged:** the actor writes them, but the rules check the real event (the like/comment/follow/Match interest must exist), the recipient, and a deterministic id per event.
- **Blocks:** a block in either direction denies likes, comments, follows and notifications; the blocker's app hides the other person's posts, comments, notifications and profile. Blocking also deletes the follows between the two.
- **Reports:** posts and comments can be reported (the reported person must be the content's author). Reports are readable only by moderators with the custom claim `admin == true` (set with the Admin SDK; the app never sets it). Moderators may also delete any post or comment.
- **Untrusted content:** text is rendered as plain text (no HTML/markdown); stored images are checked (JPEG header, size, dimensions) before decoding and decoded at display size; picked images are re-encoded without EXIF/GPS.
- **Videos:** chunks can only be created in the post's own batch (all of them, ≤ 800 KiB each, ≤ 3) and are deleted with it; the `video` description cannot be edited. The rules cannot parse MP4 bytes, so the app checks the total size and the MP4 signature before handing a downloaded file to the platform player, and strips `udta`/`meta` metadata (GPS, device) before upload. Downloaded videos are cached only in the app's private cache directory.
- **Deep links:** `skillswap://app/post/<id>` only opens a screen inside the app; the post is still read through the rules.

## App Check (quota protection)

`lib/core/app_check.dart` activates Firebase App Check at startup: Play Integrity (Android) / App Attest (iOS) in release, the debug provider in debug builds. Firestore and Auth requests then carry a token; once **enforcement** is on, requests from scripts or modified clients are rejected, which protects the Spark quota.

Console steps (Firebase Console → App Check):
1. **Apps → Android `com.skillswap.skill_swap` → Play Integrity → Register** (needs the SHA-256 of the signing key; release signing is still pending, M5).
2. **⋮ → Manage debug tokens → Add**: paste `APP_CHECK_DEBUG_TOKEN` from the git-ignored `env/dev.json` (or the "Firebase App Check debug token" line in logcat). Run with `flutter run --dart-define-from-file=env/dev.json` to keep the same token after reinstalling.
3. **APIs → Cloud Firestore → Monitor** for a few days (metrics show verified vs. unverified requests), then **Enforce**. Enforce Authentication the same way.

Do not enforce before steps 1–2: unregistered builds would get `permission-denied` everywhere.

## Sessions

Managed by Firebase Auth (refresh tokens stored by the SDK in platform storage). The app does not store tokens itself, so `flutter_secure_storage` is not needed. Sign out clears the session; the router immediately leaves protected routes.

## Data protection and privacy

- Profiles (name, bio, skills) are visible to every signed-in user by design. Email is never stored in Firestore.
- Chat content is visible only to the two members (and to project administrators via the Firebase console).
- No analytics, crash reporting, ads or third-party SDKs besides Firebase.

## Permissions

Android: `INTERNET` only. iOS: no runtime permissions.

## Transport

All Firebase traffic uses TLS. No custom HTTP clients.

## Input validation

Client: email format, password length, name/bio length, skill selection, message trimming/length. Server: types, lengths and allowed keys in rules.

## Secrets

- No secrets in the repository. `firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist` contain public client identifiers.
- Signing keystores / `key.properties` must stay out of git (`.gitignore` of the workspace).
- No service account or admin keys in the app.

## Logging

The app does not log. Do not add logging of message text, emails or tokens.

## Known risks and mitigations

Full findings and status: [audits/2026-11-20-security-audit.md](audits/2026-11-20-security-audit.md). Match screen audit: [audits/2026-11-20-match-screen-audit.md](audits/2026-11-20-match-screen-audit.md).

| Risk | Impact | Mitigation / next step |
|---|---|---|
| Blocked person can still see the blocker in Discover (MS-2) | Unwanted visibility (no match/message possible) | Server-side discovery excluding both block directions. |
| No App Check, no write rate limit (H2) | Quota exhaustion takes the app down; scripted abuse | Enable App Check; rate-limit rules; budget alerts. |
| Profiles readable by any signed-in user (in pages of ≤ 50) | Scraping is slower but possible | App Check; restrict API keys in Google Cloud. |
| No email verification, password ≥ 6 | Throwaway / squatted accounts | `sendEmailVerification`; Firebase password policy. |
| No account deletion, no privacy policy (M6) | LGPD rights, store policy | Implement deletion (Auth + Firestore cleanup). |
| Release signed with debug key, no obfuscation (M5) | Cannot publish safely | Upload keystore (needs owner approval) + `--obfuscate --split-debug-info`. |
| `allowBackup` default | Session data in device backups | Disable or add `dataExtractionRules`. |
