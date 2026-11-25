# 0005 — Community (social feed) on Firestore, Spark plan

**Status:** Accepted (2026-11-20). Revisit if the project moves to the Blaze plan.

## Context

The user asked for a "Comunidade": a social feed (posts with photos, likes, comments, saves, follows, search, notifications, reports, blocks) integrated with the existing Match, skills, chats and profiles. Constraints found in the audit:

- Firebase project `skill-suap` on the free **Spark** plan: Auth + Cloud Firestore only. No Cloud Storage (new buckets need Blaze), no Cloud Functions, no FCM sender.
- Everything that must be trusted is enforced by `firestore.rules` (ADR 0003); profile photos are inline JPEG Blobs (ADR 0004).
- Match = private `likes/{from}_{to}` + `matches/{pair}` created only on mutual interest.

## Decision

### Data model (new collections only — no existing document changes)

| Path | Purpose |
|---|---|
| `posts/{postId}` | authorId, description ≤ 2000, type (project, tip, knowledge, question, achievement, work), skillIds ≤ 5 (catalog), tags ≤ 10, keywords ≤ 40 (search), visibility = `public`, mediaCount 0–5, aspectRatios, optional `thumb` (JPEG ≤ 24 KiB), optional `video` {chunks, bytes, durationMs, width, height}, createdAt, updatedAt |
| `posts/{postId}/media/{0..4}` | `data` (JPEG ≤ 300 KiB, ≤ 1440 px), width, height. Created only in the same batch as the post (no orphans, no later additions). |
| `posts/{postId}/video/{0..2}` | `data`: one ≤ 800 KiB slice of the MP4. Created only in the post's batch, all of them (the post is refused if one is missing); deleted with the post. |
| `posts/{postId}/likes/{uid}` | one per user (doc id = uid → no duplicates) |
| `posts/{postId}/comments/{id}` | authorId, text ≤ 1000, parentId (one reply level), createdAt |
| `follows/{follower}_{following}` | public to signed-in members |
| `users/{uid}/saved/{postId}` | owner only |
| `users/{uid}/notifications/{id}` | in-app notifications, deterministic ids (no duplicates) |
| `rateLimits/{uid}` | lastPostAt / lastCommentAt: anti-spam cooldown enforced by the rules |
| `reports/{id}` | existing collection; new shape adds targetType/postId/commentId |

Counts (likes, comments, followers, following, posts) use Firestore `count()` aggregation instead of stored counters: no client can forge or drift a counter, at the cost of one read per 1000 counted documents.

### Media

Images only, stored inline (like ADR 0004): each image is decoded in an isolate, orientation applied, metadata (EXIF/GPS) dropped, resized to ≤ 1440 px and JPEG-encoded ≤ 300 KiB; a ≤ 24 KiB thumbnail of the first image goes into the post (blur-up placeholder and profile grid).

**Short videos (added 2026-11-21, user decision):** one MP4 of at most 60 s and 2.34 MiB per post, instead of images. There is no Storage or transcoding on Spark, so the file is sent as is, split into ≤ 3 chunk documents of 800 KiB (`posts/{id}/video/{i}`, below the 1 MiB document limit), in the same batch as the post. Before upload the app checks the size and the `ftyp` signature, turns the metadata boxes (`udta`, `meta`: GPS, device, author) into zeroed `free` boxes of the same size (offsets stay valid), reads length and size with the platform player, and extracts the first frame as the post's single image (poster + thumb). Playback never starts by itself: the chunks are downloaded on the first tap, reassembled, checked (total size, signature) and cached in the app's private cache directory. Costs: every first play reads 1–3 documents of up to 800 KiB (counts against the free 1 GiB storage and daily reads); larger or longer videos need Cloud Storage (Blaze).

### Visibility

Only **Público** is offered. Followers-only posts cannot be listed securely in a feed query on Firestore without a fan-out (Cloud Functions). The field `visibility` is stored (`public`) so the option can be added later.

### Match integration ("Quero aprender com …")

Reuses `DiscoverRepository.swipe` (the real Match flow): writes the like and tries to create the match; the existing rules decide. States: available → interest sent (pending) → match (open chat). An in-app notification tells the author, with the post as context; the confirmation sheet says so explicitly, because Discover likes are otherwise private.

### Notifications

In-app only (`users/{uid}/notifications`), written by the actor and validated by the rules against the real event (the like/comment/follow must exist). No push: FCM needs a server (Blaze).

### Moderation

Report post / comment / user (reasons: spam, harassment, offensive, scam, inappropriate, other), block user (hides their content, denies their likes/comments/follows on your content server-side). Reports are write-only for users; a custom claim `admin == true` (set with the Admin SDK, not by the app) can read reports and delete any post/comment.

## Alternatives rejected

- Stored like/comment counters: need rules that tie each ±1 to a like/comment write; multi-delete batches cannot be verified. `count()` is exact and unforgeable.
- Cloud Storage for media / Functions for fan-out and push: require Blaze (cost) — needs the user's approval. Video chunks in Firestore are the Spark-compatible compromise: no transcoding, no streaming (the whole file is downloaded before playing).

## Known limitations

- Posts of someone who blocked you can still appear in list queries (their block is private to them); every interaction with their content is denied by the rules.
- Deleting a post deletes the post and its images; likes, comments and notifications that point to it stay orphaned (unreadable: comment/like reads require the post to exist). Cleanup needs a Function.
- Search: people by name prefix (case-sensitive, Firestore has no full-text search), posts by one keyword or tag, skills by catalog id.
- "Seguindo" feed uses the 30 most recent follows (Firestore `whereIn` limit).
