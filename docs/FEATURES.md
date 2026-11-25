# Features

Status legend: **Implemented** = code exists and is covered as described in [TESTING.md](TESTING.md). **Planned** = not in the code.

## Implemented

### 1. Authentication (email/password)

| Item | Description |
|---|---|
| Goal | Let people create an account and sign in. |
| Expected behavior | One screen toggles between *sign in* and *create account*. On success the router moves on automatically (setup or discover). |
| Flow | Open app → `/sign-in` → enter email + password → **Entrar** / **Criar conta**. |
| Business rules | Account = Firebase Auth email/password user. Session persists across restarts. Sign out from the Profile tab. |
| Validation | Email matches `^[^@\s]+@[^@\s]+\.[^@\s]+$` (trimmed); password ≥ 6 characters. |
| Loading | Primary button shows a spinner and is disabled (no double submit); mode toggle disabled. |
| Empty state | n/a |
| Errors | Invalid credentials, email in use, weak password, network, unknown → SnackBar with human message. |
| Dependencies | `firebase_auth`, `AuthRepository`. |
| Restrictions | No password reset, social login, email verification or account deletion. |
| Special cases | `invalid-email` from Firebase is shown as "incorrect email or password" (no account enumeration). |

### 2. Profile setup and editing

| Item | Description |
|---|---|
| Goal | Describe what the person can teach and wants to learn. |
| Expected behavior | First sign-in without profile → `/setup`. After save, router moves to Discover. Editing from Profile tab opens `/profile/edit`, shows "Perfil salvo" and returns. |
| Flow | Name → optional bio → select skills under "Posso ensinar" and "Quero aprender" → **Salvar**. |
| Business rules | Skills come from a fixed catalog of 20 ids (`Skills.all`); stored in catalog order. |
| Validation | Name required, ≤ 40 chars; bio ≤ 160; at least one skill in each list (message shown after first save attempt). Rules enforce the same limits server-side. |
| Loading | Save button spinner/disabled. Initial values come from the already-loaded profile stream. |
| Empty state | New profile starts empty. |
| Errors | Save failure → SnackBar. Profile stream failure → splash shows `ErrorView` with retry. |
| Dependencies | `cloud_firestore`, `ProfileRepository`, `currentProfileProvider`. |
| Restrictions | Optional photo from the gallery: center-cropped 384 px JPEG, metadata removed, at most 48 KiB, stored inline in the profile (no Cloud Storage); initials when there is none. No skill levels. |
| Special cases | The same skill may be in both lists. |

### 3. Match screen (Discover — swipe deck)

*Redesigned 2026-11-20 (premium glass layout). Behavior below reflects the current code.*

- **Header:** logo + "SkillSwap" wordmark, notifications bell (**disabled — feature does not exist yet**), profile button (opens the Profile tab).
- **Card:** photo hero (monogram when the person has no photo), top chip "Quer aprender {skill}" (a skill they want that you teach, else their first wish), name, bio, glass chips for "Ensina" / "Quer aprender" (connected skills first, lime border + check), and the **Match de conhecimento** banner.
- **Knowledge match (real data only):** `exchange` (you teach X and learn Y with them), `teach` (you know X and they want it), `learn` (they know Y, which you want). No banner when skills don't connect. The previous "% compatível" badge was removed from the card; the score is still used only to order the deck.
- **Actions:** Undo (dark, enabled only right after a skip), Skip (white, red X), Interested (lime, black ✓, most prominent), Save (dark star, **disabled — feature does not exist yet**).
- **Business rules:** only the last *skip* can be undone (an approval may already have created a match). Undo restores the card in this session; the stored `liked: false` stays until the user decides again (overwriting it). An approval is never treated as mutual: a match exists only if the server rules accept it.
- **Not shown because the data does not exist:** age, city, verified badge, knowledge level.

### 3a. Previous Discover notes (still valid)

| Item | Description |
|---|---|
| Goal | Present compatible people one at a time. |
| Expected behavior | Top card shows initials, name, compatibility %, bio, "Ensina" and "Quer aprender" tags. Tags that match your interests are highlighted (lime + check icon). Next card peeks behind. |
| Flow | Drag right / tap **Tenho interesse** → like. Drag left / tap **Pular** → skip. |
| Business rules | Candidates: users whose `teach` contains any of your `learn` (all users if your `learn` is empty), excluding you and anyone you already swiped; max 50 per load; sorted by `Compatibility.score` desc. Score = mean of (share of your wishes they teach) and (share of their wishes you teach), 0–100. |
| Validation | n/a |
| Loading | Centered spinner while fetching. |
| Empty state | "Ninguém novo por enquanto" + **Atualizar**. |
| Errors | Load failure → `ErrorView` + retry. Swipe failure → card restored + SnackBar. |
| Dependencies | `DiscoverRepository`, `DiscoverController`, `SwipeCard`. |
| Restrictions | Swipes are final (no undo). No filters. |
| Special cases | Drag commits past 30% of card width or fling > 900 px/s; otherwise snaps back. Reduced motion → no animation. |

### 4. Matching

| Item | Description |
|---|---|
| Goal | Unlock contact only on mutual interest. |
| Expected behavior | When you like someone who already liked you, a "Deu match!" dialog offers **Enviar mensagem** or **Continuar explorando**. |
| Business rules | Like stored at `likes/{you}_{them}`. A match document `matches/{uidA}_{uidB}` (sorted ids) is created only if both likes exist with `liked == true` — enforced by Security Rules. Idempotent: existing match is not recreated. |
| Errors | Rule rejection / network → SnackBar, card restored. |
| Restrictions | The person who liked first is not notified in real time except through the Matches tab updating. |

### 5. Matches list

| Item | Description |
|---|---|
| Goal | Access every conversation. |
| Behavior | Real-time list ordered by last activity; subtitle = last message or "Diga oi para começar a troca" (with a "new" icon). |
| Loading / empty / error | Spinner / "Nenhum match ainda" / `ErrorView` + retry. |
| Dependencies | `matchesProvider`. |

### 6. Chat

| Item | Description |
|---|---|
| Goal | Agree on topics, format and time. |
| Behavior | Real-time messages, newest at the bottom; own bubbles lime, other person's dark gray; time `HH:mm` in device locale. |
| Business rules | Only the two members can read/write (rules). Message text trimmed; empty ignored; max 2000 chars (UI limit, repository truncation, rules check). Sending also updates the match preview atomically (batch). |
| Validation | Send button disabled while text is blank or sending. |
| Loading / empty / error | Spinner / "Diga oi…" hint / `ErrorView` + retry; send failure → SnackBar (text kept). |
| Restrictions | Latest 100 messages only; no read receipts, typing indicators, media or deletion. |

### 7. Safety: consent, unmatch, block, report

| Item | Description |
|---|---|
| Goal | Protect people who meet strangers through the app. |
| Consent | Profile setup has a required checkbox "I am 18 or older and accept the Terms and Community rules" with a link to the terms screen. The profile is saved together with a private consent record (server-enforced). Accounts created before this see a consent screen (accept or sign out) before anything else. |
| Unmatch | Chat menu → **Desfazer match** → confirmation. Closes the conversation for both; it disappears from Matches; history stays readable only if the chat is opened by URL; no new messages. Final. |
| Block | Chat menu → **Bloquear** → confirmation. Closes the match and prevents any future match or message with that person. The blocked person is not notified. Final (no unblock yet). |
| Report | Chat menu → **Denunciar**, or the flag icon on a Discover card. Bottom sheet: reason (harassment, spam/scam, inappropriate, fake profile, other — required) and optional details (≤ 500). Sending also blocks the person and closes the match. Confirmation SnackBar. |
| Validation | Reason required (inline error); consent checkbox required (inline error). |
| Loading / errors | Buttons show spinners and disable; failures show a SnackBar and keep the user on the screen. |
| Moderation | Reports are readable only in the Firebase console (project team). No automated moderation, no appeal flow. |
| Restrictions | Age is self-declared. Users who blocked you can still appear in your Discover deck (liking them has no effect) because blocks are private. |

### 7a. Comunidade (social feed)

See [ADR 0005](adr/0005-community.md) for the data model, rules and limits.

| Area | What works | Data |
|---|---|---|
| Feed | Para você (recent), Seguindo (30 most recent follows), Skills (your teach + learn), Projetos; pagination, pull to refresh, hides blocked people | `posts` |
| Publish | Text, ≤ 5 images **or** 1 video (MP4 ≤ 60 s, ≤ 2.3 MB, location metadata removed, poster frame), type, ≤ 5 skills, ≤ 10 hashtags, preview, progress, edit, delete | `posts`, `posts/{id}/media`, `posts/{id}/video`, `rateLimits` |
| Watch a video | Poster + duration; plays only on tap (downloaded then, cached); pause, scrubbing, mute, full screen with the original proportion; pauses when leaving the tab/screen or the app | `posts/{id}/video` |
| Interact | Like, comment + reply, share (link / chat), save | `likes`, `comments`, `users/{uid}/saved` |
| People | Follow, followers/following lists, member profile + portfolio | `follows` |
| Match | "Quero aprender com …" → like + match attempt (existing flow); open chat when matched | `likes`, `matches` |
| Notifications | Like, comment, reply, follow, learn request (in-app) | `users/{uid}/notifications` |
| Safety | Report post/comment/member, block | `reports`, `blocks` |

Not available (needs the Blaze plan or more backend work): long or large videos (> 60 s / 2.3 MB), video streaming/transcoding, followers-only posts, push notifications, notification preferences, cleanup of likes/comments of deleted posts, full-text search, admin panel.

### 8. Localization and theme

Portuguese (default fallback) and English UI; dark brand theme always on (light theme defined but not exposed). See [LOCALIZATION.md](LOCALIZATION.md) and [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

## Planned (from the project brief, not implemented)

- Ratings after an exchange.
- Filters by area or level.
- Push notifications (new match / message).
- Activity history.
- Scheduling of learning sessions.
- Account deletion.

## Discontinued

None.
