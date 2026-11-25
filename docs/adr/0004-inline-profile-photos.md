# 0004 — Store profile photos inline in Firestore

**Status:** Accepted (revisit if photos grow or the project moves to the Blaze plan)

## Context

Profiles needed a photo. The project runs on the free Spark plan; new Cloud Storage buckets require the paid Blaze plan.

## Alternatives considered

1. **Cloud Storage** + `photoUrl` in the profile — standard, CDN-cached, but needs Blaze (billing) and a second set of rules.
2. **External avatar URL** (e.g. a generated-avatar service) — no upload; but users cannot use their own photo and every view leaks requests to a third party.
3. **Small JPEG inline** in `users/{uid}.photo` (Firestore `Blob`).

## Decision

Option 3, decided with the user on 2026-11-20. The app picks an image (`image_picker`, downsized by the platform to ≤ 1024 px), then in a background isolate (`image` package) applies the EXIF orientation, center-crops to 384×384, flattens transparency onto white and re-encodes as JPEG (quality 85 → 50 until ≤ 48 KiB). The new image carries no EXIF/GPS or color profile.

## Security

- Rules: `photo` optional; must be `bytes`, 4 B – 48 KiB, starting with `FF D8 FF` (JPEG). Owner-only write, like the rest of the profile. Tested in `firestore_rules_test/`.
- Readers: `UserProfile.fromMap` keeps a photo only if the JPEG header declares at most 1024×1024 (decompression-bomb guard), and `ProfileAvatar` decodes at the displayed size (`cacheWidth`), falling back to initials on any decode error.
- No content moderation yet: inappropriate photos can be reported through the existing report flow (reason "inappropriate").

## Consequences

- Discover reads up to 50 profiles: worst case ~5 MB, typical ~0.5–1.5 MB (avatars are ~10–40 KB). Acceptable at this scale; move to Storage if it hurts.
- Every profile listener receives the photo bytes; profile edits re-send them.
- Migrating to Storage later: add `photoUrl`, backfill, then drop `photo`.
