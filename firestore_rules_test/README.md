# Firestore Security Rules tests

Tests for [`../firestore.rules`](../firestore.rules) using `@firebase/rules-unit-testing` and Node's built-in test runner, against the **local** Firestore Emulator. The project id `demo-skill-swap` is a demo project: nothing is sent to the real Firebase project.

Requirements: Node 18+, Java 21+ (Android Studio's bundled JBR works), Firebase CLI.

```powershell
npm install
```

From the Flutter project root (`skill_swap/`), with Java on the path for this terminal:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'; $env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase.cmd emulators:exec --only firestore --project demo-skill-swap "npm --prefix firestore_rules_test test"
```

Every rule change must keep these tests green; add a failing test first for any new rule or bug.
