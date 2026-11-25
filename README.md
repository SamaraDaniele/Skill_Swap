# Skill Swap

A mobile skill-exchange platform. Each person lists what they can teach and what they want to learn, discovers compatible people through a swipe deck, gets a match when interest is mutual, and talks to the match in a private chat. No payment is involved: knowledge is the currency.

Built for the *Projeto Integrador* course ("Plataforma de conexão e troca de conhecimentos").

> End-user language: Brazilian Portuguese (default) and English.

## Features (implemented)

- Email/password sign-up and sign-in (Firebase Auth).
- Profile creation and editing: name, short bio, skills to teach, skills to learn (20-skill catalog).
- Discover: swipe deck of people who teach something you want to learn, ranked by a mutual-compatibility score; drag or use buttons to choose **Interested** / **Skip**.
- Mutual interest creates a match (enforced by Firestore Security Rules).
- Matches list with last-message preview.
- Real-time private chat per match.
- **Comunidade** (5th tab, center): social feed of projects, tips, questions and achievements with up to 5 photos per post, likes, comments with replies, saved posts, follows, search (people, words/#tags, skills), in-app notifications, report/block, and a member profile with a portfolio grid. "Quero aprender com …" on a post sends interest through the existing Match flow. See [docs/adr/0005-community.md](docs/adr/0005-community.md).
- Black / White / Lime (`#000000` / `#FFFFFF` / `#CBF615`) Material 3 design system, dark theme by default.

Planned but **not implemented**: ratings, filters, push notifications, activity history, report/block, session scheduling. See [docs/FEATURES.md](docs/FEATURES.md).

## Tech stack

| Area | Choice | Version (resolved) |
|---|---|---|
| SDK | Flutter stable / Dart | 3.50.1 / 3.14.0 |
| UI | `material_ui`, `cupertino_ui` (Material 3) | 1.11.x / 1.1.x |
| State | `flutter_riverpod` | 3.5.0 |
| Navigation | `go_router` | 18.1.4 |
| Backend | `firebase_core`, `firebase_auth`, `cloud_firestore` | 5.2.0 / 7.1.0 / 7.2.0 |
| i18n | `flutter_localizations`, `intl`, ARB files | SDK / 0.20.3 |
| Tests | `flutter_test`, `fake_cloud_firestore`, `firebase_auth_mocks` | — |

Targets: Android and iOS (iOS builds require macOS + Xcode).

## Architecture at a glance

Feature-first structure, Riverpod for state and dependency injection, repositories talking directly to Firebase, go_router with auth/profile redirects. Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

```
lib/
  main.dart               Firebase init + ProviderScope
  app.dart                MaterialApp.router (themes, l10n, router)
  firebase_options.dart   placeholder, overwritten by `flutterfire configure`
  core/
    error/failure.dart    sealed Failure + Firebase error mapping
    firebase_providers.dart
    l10n/l10n.dart        context.l10n, delegates, error messages
    router/               routes + redirect logic + bottom navigation shell
    theme/                tokens (colors, spacing, radius, motion) + ThemeData
    widgets/app_widgets.dart  shared components
  features/
    auth/                 AuthRepository + SignInScreen
    profile/              UserProfile, Compatibility, ProfileRepository, skill catalog, screens
    discover/             DiscoverRepository, DiscoverController, swipe deck
    matches/              Match, ChatMessage, MatchRepository, matches + chat screens
  l10n/                   app_en.arb (template), app_pt.arb, generated code
test/                     unit, repository and widget tests
firestore.rules           server-side authorization
```

## Getting started

Full guide: [docs/SETUP.md](docs/SETUP.md). Short version:

```bash
flutter pub get
```

```bash
dart pub global activate flutterfire_cli
```

```bash
flutterfire configure
```

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

```bash
flutter run
```

On Windows with restricted PowerShell scripts, use `npm.cmd` / `firebase.cmd` (see [docs/SETUP.md](docs/SETUP.md)). The current checkout is already configured for the Firebase project `skill-suap`; other developers only need `flutterfire configure` to point it at their own project.

Firebase project prerequisites: **Authentication → Email/Password** enabled and a **Cloud Firestore** database created. Platforms not configured by `flutterfire configure` stop at startup with `DefaultFirebaseOptions have not been configured for <platform>`.

### Environment variables

The app reads no `--dart-define` values. The only configuration is `lib/firebase_options.dart` (generated) plus the native files `flutterfire` writes (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`). Firebase client keys identify the project and are not secrets; access is controlled by `firestore.rules`.

## Build

```bash
flutter build apk --release
```

```bash
flutter build appbundle --release
```

```bash
flutter build ipa --release
```

Release signing is not configured yet. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Tests

```bash
dart format --output=none --set-exit-if-changed .
```

```bash
flutter analyze
```

```bash
flutter test
```

Security Rules tests (Firestore Emulator, local only): see [firestore_rules_test/README.md](firestore_rules_test/README.md).

Coverage and status: [docs/TESTING.md](docs/TESTING.md). Security audit: [docs/audits/2026-11-20-security-audit.md](docs/audits/2026-11-20-security-audit.md).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `UnsupportedError: DefaultFirebaseOptions …` | Run `flutterfire configure` for that platform. |
| `firebase` / `npm` "not recognized" or `UnauthorizedAccess` on Windows | Use `firebase.cmd` / `npm.cmd`; open a new terminal after installing. |
| `permission-denied` / "Você não tem permissão" | Deploy `firestore.rules`; make sure you are signed in. |
| `No MaterialLocalizations found` in a custom test harness | Use `appLocalizationsDelegates` from `core/l10n/l10n.dart`, not `AppLocalizations.localizationsDelegates`. |
| Discover is always empty | Other users must teach a skill in your "I want to learn" list; profiles you already swiped are hidden. |
| Generated l10n files missing | `flutter gen-l10n` (also runs on `flutter pub get`). |

## Known limitations

- Discover fetches at most 50 candidates per load and ranks them on the client.
- Chat shows the latest 100 messages; no history pagination.
- Match creation runs on the client (validated by Security Rules), not in a Cloud Function.
- No release signing, CI, push notifications, or account deletion yet.
- Community (Spark plan, see ADR 0005): images or one short video (≤ 60 s, ≤ 2.3 MB, stored in Firestore chunks; no streaming), public posts only (no followers-only visibility), in-app notifications only (no push), name search is a case-sensitive prefix match, deleting a post leaves its likes/comments orphaned (unreadable), and posts of someone who blocked you can still appear in lists (interactions are denied).
- Verified end to end on the Android emulator only (not yet iOS or a physical device); no performance measurements exist ([docs/PERFORMANCE.md](docs/PERFORMANCE.md)).
- Android emulator on this machine needs software rendering: use `tool/run_android.ps1` ([docs/SETUP.md](docs/SETUP.md)). The script runs with `--no-enable-impeller` because the emulator's software GPU (SwiftShader) crashes compiling some Impeller shaders; real devices use Impeller. Give the AVD at least 3 GB of RAM, or System UI stops responding.

## Documentation

[Architecture](docs/ARCHITECTURE.md) · [Features](docs/FEATURES.md) · [Screens](docs/SCREENS.md) · [Design system](docs/DESIGN_SYSTEM.md) · [Components](docs/COMPONENTS.md) · [API & integrations](docs/API.md) · [Data models](docs/DATA_MODELS.md) · [Security](docs/SECURITY.md) · [Performance](docs/PERFORMANCE.md) · [Setup](docs/SETUP.md) · [Deployment](docs/DEPLOYMENT.md) · [Testing](docs/TESTING.md) · [Localization](docs/LOCALIZATION.md) · [ADRs](docs/adr/) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)
