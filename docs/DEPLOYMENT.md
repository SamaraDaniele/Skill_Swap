# Build and Deployment

> Nothing has been published. Release signing, store listings and CI are **not configured**. Publishing and creating signing keys require explicit approval from the project owner.

## Environments

There is one environment: whichever Firebase project `flutterfire configure` points to. For separate dev/prod, create two Firebase projects and generate per-flavor options (`flutterfire configure --project=<id> --out=lib/firebase_options_dev.dart`), then select the file per flavor — not implemented yet.

## Versioning

`version:` in `pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`, currently `0.1.0+1`). Bump the build number for every store upload; follow SemVer for the name; record changes in [CHANGELOG.md](../CHANGELOG.md).

## Android

Identifiers: `applicationId = com.skillswap.skill_swap`, label "Skill Swap".

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk`, `build/app/outputs/bundle/release/app-release.aab`.

### Signing (to do)

Currently release builds use the debug key (Flutter template default) — fine for testing, **not** accepted by Google Play.

1. Create an upload keystore outside the repo (`keytool -genkey -v -keystore <path>/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`).
2. Create `android/key.properties` (ignored by git) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. Load it in `android/app/build.gradle.kts` `signingConfigs.release`.
4. Add the release SHA-1/SHA-256 to the Firebase Android app.

Never commit keystores, `key.properties` or passwords.

## iOS (macOS only)

Bundle id from the template: check `ios/Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`). Display name "Skill Swap".

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

Requires an Apple Developer account, signing team set in Xcode, and `GoogleService-Info.plist` from `flutterfire configure`. Upload with Xcode Organizer or Transporter.

## Before a release

1. `dart format`, `flutter analyze`, `flutter test` green.
2. Deploy and test `firestore.rules`.
3. Test on a real Android and iOS device.
4. Update CHANGELOG and version.
5. Keep `build/symbols` to symbolize crashes.

## Publishing

Google Play Console: internal testing track → closed → production. App Store Connect: TestFlight → review. Both stores require a privacy policy and in-app account deletion for apps with accounts (not implemented yet — blocker).

## Updates and rollback

- Stores: roll out gradually (Play staged rollout / App Store phased release); halt the rollout if issues appear; ship a fixed build with a higher build number (stores do not allow downgrades).
- Firestore rules: redeploy the previous `firestore.rules` from git (`firebase deploy --only firestore:rules`); the console also keeps rule history.
