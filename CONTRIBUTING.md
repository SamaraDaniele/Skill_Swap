# Contributing

## Code standards

- Dart 3, null safety without gratuitous `!`, `final`/`const` everywhere possible.
- After every `await` in a widget, check `mounted` / `context.mounted` before using `context` or `setState`.
- Dispose every controller you create.
- Repositories wrap Firebase calls with `guard()` / `.mapFailures()`; the UI shows `l10n.failureMessage(error)`. Never show raw exceptions.
- No logging of personal data (emails, message text, tokens).
- Lints: `analysis_options.yaml` (flutter_lints + strict casts/raw types, const, trailing commas, `unawaited_futures`). Zero analyzer issues is required.

## Naming

- All code, comments, file names, ARB keys and docs in English.
- Files `snake_case.dart`; classes `PascalCase`; providers `somethingProvider`; screens `XScreen`; repositories `XRepository`.
- User-facing text only in ARB files ([docs/LOCALIZATION.md](docs/LOCALIZATION.md)).

## File organization

```
lib/core/       shared, feature-agnostic code
lib/features/<feature>/
  <feature>.dart        models + repository + providers
  <name>_screen.dart    screens
  <widget>.dart         feature-only widgets
```

A widget used by two or more features moves to `lib/core/widgets/`. Don't add layers (use cases, interfaces) unless the feature's complexity calls for it — record the decision as an ADR.

## Design system rules

Use tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppMotion`) and the theme; never hard-code colors or random spacing. Every screen needs loading, empty and error states; icon-only buttons need tooltips; touch targets ≥ 48 dp; respect reduced motion. Details: [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md).

## Dependencies

Add only with a concrete need, via `flutter pub add`, and state the reason in the PR.

## Process

1. Branch from `main`: `feat/…`, `fix/…`, `docs/…`.
2. Implement with tests.
3. Run format, analyze, test (see [docs/TESTING.md](docs/TESTING.md)).
4. Update affected docs and `CHANGELOG.md` (`[Unreleased]`).
5. Open a PR; at least one review. Changes to auth, rules or data need a security-focused review.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/): `feat(discover): add undo for last swipe`, `fix(chat): keep text when send fails`, `docs: …`, `test: …`, `refactor: …`, `chore: …`.

## Tests

New logic → unit or repository test; new screen or state → widget test; bug fix → regression test. Use `harness()` and provider overrides as in `test/widgets_test.dart`.

Security first: any change to `firestore.rules` needs both an attack test (must fail) and a legitimate-use test (must pass) in `firestore_rules_test/`, and a green run before deploying. Adding a skill means updating `Skills.all`, the ARB files and `skillIds()` in the rules together. Never trust the client for anything another user sees (names, previews, timestamps).

## Documentation

The docs must describe what the code does, not what is planned. When you change behavior: update FEATURES/SCREENS/COMPONENTS/DATA_MODELS as relevant, fix code examples, mark unimplemented items as planned, check internal links, and add a CHANGELOG entry.
