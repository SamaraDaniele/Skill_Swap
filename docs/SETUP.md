# Setup

## 1. Prerequisites

| Tool | Version used | Notes |
|---|---|---|
| Flutter (stable) | 3.50.1 | Includes Dart 3.14.0. `pubspec.yaml` requires Dart `^3.14.0`. |
| Android Studio + Android SDK | latest stable | For Android builds/emulators. |
| Xcode + CocoaPods | latest stable | iOS only, macOS only. |
| Node.js | LTS | For `firebase-tools`. |
| Firebase account | — | Free Spark plan is enough for development. |

## 2. Install Flutter

Follow https://docs.flutter.dev/get-started/install for your OS, then:

```bash
flutter doctor
```

Fix everything `flutter doctor` reports for the platforms you need.

### Android SDK

Install Android Studio → SDK Manager: Android SDK Platform (latest), Build-Tools, Command-line Tools, Platform-Tools. Accept licenses:

```bash
flutter doctor --android-licenses
```

### Xcode (iOS)

Install Xcode from the App Store, then:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

```bash
sudo gem install cocoapods
```

Open `ios/Runner.xcworkspace` once to select your development team for signing on devices.

## 3. Dependencies

From the project folder (`skill_swap/`):

```bash
flutter pub get
```

This also generates localization code (`lib/l10n/app_localizations*.dart`).

## 4. Firebase configuration

1. Create a project in the Firebase console.
2. **Authentication → Sign-in method → Email/Password**: enable.
3. **Firestore Database → Create database** (production mode; rules come next).
4. Install the CLIs and log in:

```bash
npm install -g firebase-tools
```

```bash
firebase login
```

```bash
dart pub global activate flutterfire_cli
```

5. Generate the config (choose Android and iOS). This overwrites `lib/firebase_options.dart` and adds the native config files:

```bash
flutterfire configure
```

6. Deploy the security rules. `firebase.json` (committed) already points to `firestore.rules`:

```bash
firebase deploy --only firestore:rules --project <your-project-id>
```

> **Windows:** if PowerShell's execution policy blocks `.ps1` scripts (`UnauthorizedAccess` / "not recognized"), call the `.cmd` shims instead: `npm.cmd`, `firebase.cmd`. Run `flutterfire` as `dart pub global run flutterfire_cli:flutterfire configure` when `%LOCALAPPDATA%\Pub\Cache\bin` is not on PATH. Run it inside `skill_swap/` (the folder with `pubspec.yaml`).
>
> **iOS:** `flutterfire configure` run on Windows does not write `ios/Runner/GoogleService-Info.plist`. The app initializes Firebase from `firebase_options.dart`, which is enough for Auth and Firestore; re-run `flutterfire configure` on a Mac if a native-config feature (e.g., push notifications) is added.

There are no other environment variables.

## 5. Run

```bash
flutter devices
```

```bash
flutter run
```

### Emulators

- Android (one command): `tool/run_android.ps1` installs the NDK the Android Gradle plugin needs (`tool/install_ndk.ps1`), stops stale emulator processes, boots the AVD with software rendering and runs the app:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_android.ps1
```

  Parameters: `-Avd Pixel_8_API_36`, `-Sdk C:\src\android-sdk`, `-ColdBoot`. Software rendering (`-gpu swiftshader_indirect`) is used because on the development laptop the GPU driver does not give the emulator an OpenGL core profile (`Could not start renderer`).
- `tool/seed_test_users.ps1` creates/refreshes the 5 test accounts `teste1@gmail.com` … `teste5@gmail.com` with complete profiles, photos, likes and one chat (see TESTING.md). `tool/generate_demo_avatars.ps1` redraws their illustrated avatars.
- `tool/adb.ps1` helps manual checks: `shot <name>` (saves `build/screens/<name>.png`), `tap x y`, `text '...'`, `key BACK`.
- Manual alternative: Android Studio → Device Manager → create a Pixel image (API 34+), start it, then `flutter run`.
- iOS: `open -a Simulator`, then `flutter run`.

### Physical devices

- Android: enable Developer options → USB debugging, connect, accept the prompt.
- iOS: connect, trust the computer, set the signing team in Xcode, enable Developer Mode on the device.

## 6. Verify

```bash
flutter test
```

Create two accounts (two devices/emulators or sign out and in), give them complementary skills (A teaches Excel and wants English; B the opposite), like each other → match → chat.

## Common errors

| Error | Cause / fix |
|---|---|
| `Firebase is not configured. Run flutterfire configure first.` | Step 4.5 not done. |
| `[cloud_firestore/permission-denied]` | Rules not deployed or user signed out. |
| `[firebase_auth/operation-not-allowed]` | Email/Password provider not enabled. |
| `flutterfire: command not found` | Add the Dart pub cache `bin` to PATH. |
| CocoaPods errors on iOS | `cd ios && pod install --repo-update`. |
| Android minSdk error from Firebase | Raise `minSdk` in `android/app/build.gradle.kts` to what the error requests. |
| `sdkmanager did not install NDK 28.2.13676358` | Run `tool/install_ndk.ps1` (or `tool/run_android.ps1`). |
| `kernel_snapshot_program failed` with errors inside the Flutter SDK (e.g. `_window_win32.dart`) | Stale build cache: `flutter clean`, then build again. |
| Emulator: `OpenGL Core Profile not supported` / `Could not start renderer` | Start with `-gpu swiftshader_indirect` (what `tool/run_android.ps1` does). |
