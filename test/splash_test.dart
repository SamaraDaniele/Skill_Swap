import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/startup/skill_swap_splash_screen.dart';
import 'package:skill_swap/core/startup/startup_state.dart';
import 'package:skill_swap/features/profile/profile.dart';

const _me = UserProfile(
  id: 'me',
  name: 'Ana',
  bio: '',
  teach: ['excel'],
  learn: ['english'],
);

/// Counts how many times its state is created (to detect rebuilt subtrees).
class _Probe extends StatefulWidget {
  const _Probe({required this.onTap});

  static int created = 0;
  final VoidCallback onTap;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.created++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(onPressed: widget.onTap, child: const Text('App')),
    ),
  );
}

/// Advances time frame by frame (16 ms steps, 60 Hz), like a running device.
Future<void> advance(WidgetTester tester, int milliseconds) async {
  for (var t = 0; t < milliseconds; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Finder get _logo =>
    find.byWidgetPredicate((w) => w is Image && w.image is ResizeImage);

void main() {
  group('isStartupResolved', () {
    test('waits for the session check', () {
      expect(
        isStartupResolved(
          auth: const AsyncLoading(),
          profile: const AsyncLoading(),
          consent: const AsyncLoading(),
        ),
        isFalse,
      );
    });

    test('signed out is resolved (go to sign in)', () {
      expect(
        isStartupResolved(
          auth: const AsyncData(null),
          profile: const AsyncLoading(),
          consent: const AsyncLoading(),
        ),
        isTrue,
      );
    });

    test('signed in waits for profile and consent', () {
      expect(
        isStartupResolved(
          auth: const AsyncData('me'),
          profile: const AsyncLoading(),
          consent: const AsyncLoading(),
        ),
        isFalse,
      );
      expect(
        isStartupResolved(
          auth: const AsyncData('me'),
          profile: const AsyncData(_me),
          consent: const AsyncLoading(),
        ),
        isFalse,
      );
      expect(
        isStartupResolved(
          auth: const AsyncData('me'),
          profile: const AsyncData(_me),
          consent: const AsyncData(true),
        ),
        isTrue,
      );
    });

    test('a user without profile is resolved (go to setup)', () {
      expect(
        isStartupResolved(
          auth: const AsyncData('me'),
          profile: const AsyncData(null),
          consent: const AsyncLoading(),
        ),
        isTrue,
      );
    });

    test('errors are resolved so the error screen can show', () {
      expect(
        isStartupResolved(
          auth: const AsyncData('me'),
          profile: AsyncError(Exception('x'), StackTrace.empty),
          consent: const AsyncLoading(),
        ),
        isTrue,
      );
    });
  });

  group('SkillSwapSplashScreen', () {
    late int taps;
    late int finished;
    late ValueNotifier<bool> ready;

    setUp(() {
      taps = 0;
      finished = 0;
      ready = ValueNotifier(false);
      _Probe.created = 0;
    });

    Widget app({bool reduceMotion = false, ValueNotifier<Size>? size}) =>
        MaterialApp(
          home: ValueListenableBuilder<Size?>(
            valueListenable: size ?? ValueNotifier<Size?>(null),
            builder: (context, screenSize, _) => Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    disableAnimations: reduceMotion,
                    size: screenSize ?? media.size,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: ready,
                    builder: (context, isReady, _) => SkillSwapSplashScreen(
                      ready: isReady,
                      onFinished: () => finished++,
                      child: _Probe(onTap: () => taps++),
                    ),
                  ),
                );
              },
            ),
          ),
        );

    testWidgets('fast startup: full animation, then reveal, once', (
      tester,
    ) async {
      ready.value = true;
      await tester.pumpWidget(app());

      expect(_logo, findsOneWidget);
      // Covered app is not interactive during the splash.
      await tester.tap(find.text('App'), warnIfMissed: false);
      expect(taps, 0);

      // Precache wait (≤300 ms) + intro 1600 ms: still on screen.
      await advance(tester, 300);
      await advance(tester, 1500);
      expect(_logo, findsOneWidget);
      expect(finished, 0);

      // Intro end + 600 ms reveal (with margin for the ≤300 ms image wait).
      await advance(tester, 1000);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);

      await tester.tap(find.text('App'));
      expect(taps, 1);
      // The app below was built once and kept its state.
      expect(_Probe.created, 1);

      await advance(tester, 5000);
      expect(finished, 1, reason: 'the animation must not repeat');
    });

    testWidgets('slow startup: logo stays until ready, no extra delay', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await advance(tester, 300);
      await advance(tester, 1600);
      await advance(tester, 3000);
      expect(_logo, findsOneWidget, reason: 'startup not resolved yet');
      expect(finished, 0);

      ready.value = true;
      await tester.pump();
      await advance(tester, 650);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);
      expect(_Probe.created, 1);
    });

    testWidgets('ready before the intro ends still plays the intro', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await advance(tester, 500);
      ready.value = true;
      await advance(tester, 800);
      expect(_logo, findsOneWidget);
      await advance(tester, 1500);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);
    });

    testWidgets('reduced motion: static logo and a short fade', (tester) async {
      await tester.pumpWidget(app(reduceMotion: true));
      await tester.pump();
      final scale = tester.widget<ScaleTransition>(
        find.ancestor(of: _logo, matching: find.byType(ScaleTransition)),
      );
      final first = scale.scale.value;
      await advance(tester, 500);
      expect(scale.scale.value, first, reason: 'no motion');
      expect(_logo, findsOneWidget);

      ready.value = true;
      await tester.pump();
      await advance(tester, 200);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);
    });

    testWidgets('a stalled startup frame does not skip the fade-in', (
      tester,
    ) async {
      ready.value = true;
      await tester.pumpWidget(app());
      await tester.pump(); // first frame: the intro starts
      // The UI thread stalls for a full second (heavy first build).
      await tester.pump(const Duration(seconds: 1));
      final logoFade = tester.widget<FadeTransition>(
        find.ancestor(of: _logo, matching: find.byType(FadeTransition)).first,
      );
      expect(
        logoFade.opacity.value,
        lessThan(0.5),
        reason: 'only ~2 frames of progress after a stall, not 1 s',
      );
      // It then plays out normally and reveals the app.
      await advance(tester, 2500);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);
    });

    testWidgets('a 0x0 window at launch waits for real metrics', (
      tester,
    ) async {
      final size = ValueNotifier(Size.zero);
      addTearDown(size.dispose);
      ready.value = true;
      await tester.pumpWidget(app(size: size));

      // No 0-px decode request (it fails with "empty dimensions").
      final logo = tester.widget<Image>(_logo).image as ResizeImage;
      expect(logo.width, greaterThanOrEqualTo(16));
      await advance(tester, 3000);
      expect(tester.takeException(), isNull);
      expect(_logo, findsOneWidget, reason: 'intro waits for a real size');
      expect(finished, 0);

      size.value = const Size(400, 800);
      await advance(tester, 3000);
      await tester.pump();
      expect(_logo, findsNothing);
      expect(finished, 1);
    });

    testWidgets('disposing mid-animation leaves no running tickers', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await advance(tester, 400);
      await tester.pumpWidget(const SizedBox());
      // pumpWidget/testWidgets fail if a ticker or timer is still active.
      await advance(tester, 3000);
      expect(finished, 0);
    });
  });
}
