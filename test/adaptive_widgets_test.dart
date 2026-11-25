// Shared adaptive building blocks: names, content width, action sheets,
// the bottom bar's label scale and the profile header.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/core/utils/person_name.dart';
import 'package:skill_swap/core/widgets/app_widgets.dart';
import 'package:skill_swap/core/widgets/line_icons.dart';
import 'package:skill_swap/core/widgets/neon_nav_bar.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/profile/profile_screen.dart';

/// Pumps [child] in the app theme at [size] and [textScale].
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(412, 915),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PersonName', () {
    test('first word, ignoring extra whitespace', () {
      expect(PersonName.first('  Ana   Lima '), 'Ana');
      expect(PersonName.first('Bia'), 'Bia');
      expect(PersonName.first('   '), '');
    });

    test('two uppercase initials, accents and emoji kept whole', () {
      expect(PersonName.initials('ana lima souza'), 'AL');
      expect(PersonName.initials('Ítalo'), 'Í');
      expect(PersonName.initials('👩🏽‍💻 Dev'), '👩🏽‍💻D');
      expect(PersonName.initials(''), '');
    });
  });

  group('ContentWidth', () {
    Future<Size> childSize(WidgetTester tester, Size window) async {
      await _pump(
        tester,
        const Scaffold(
          body: ContentWidth(child: SizedBox.expand(key: Key('content'))),
        ),
        size: window,
      );
      return tester.getSize(find.byKey(const Key('content')));
    }

    testWidgets('phones keep the full width', (tester) async {
      expect((await childSize(tester, const Size(412, 915))).width, 412);
    });

    testWidgets('tablets get a centered readable column', (tester) async {
      final size = await childSize(tester, const Size(1024, 1366));
      expect(size.width, ContentWidth.readable);
      expect(tester.getCenter(find.byKey(const Key('content'))).dx, 1024 / 2);
    });
  });

  group('ContentWidth across sizes and insets', () {
    testWidgets('crossing the cap keeps focus and scroll position', (
      tester,
    ) async {
      final focus = FocusNode();
      final scroll = ScrollController();
      addTearDown(focus.dispose);
      addTearDown(scroll.dispose);
      await _pump(
        tester,
        Scaffold(
          body: ContentWidth(
            child: ListView(
              controller: scroll,
              children: [
                TextField(focusNode: focus),
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('linha $i')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      scroll.jumpTo(30);
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      // Rotation / split screen: from a phone width to a wide window.
      tester.view.physicalSize = const Size(900, 600);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue, reason: 'keyboard would close');
      expect(scroll.offset, 30, reason: 'list would jump to the top');
      expect(
        tester.getSize(find.byType(ListView)).width,
        ContentWidth.readable,
      );
    });

    testWidgets('notch insets are folded into the margins, not added', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(left: 47, right: 47);
      tester.view.viewPadding = const FakeViewPadding(left: 47, right: 47);
      addTearDown(tester.view.reset);
      final Key content = UniqueKey();
      for (final (width, expected) in [(932.0, 720.0), (700.0, 606.0)]) {
        await _pump(
          tester,
          Scaffold(
            body: ContentWidth(
              child: SafeArea(child: SizedBox.expand(key: content)),
            ),
          ),
          size: Size(width, 430),
        );
        final rect = tester.getRect(find.byKey(content));
        expect(rect.width, expected, reason: 'width at $width');
        expect(rect.center.dx, width / 2, reason: 'centered at $width');
      }
    });
  });

  group('showActionSheet', () {
    testWidgets('long action lists scroll instead of overflowing on a phone '
        'in landscape with large text', (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showActionSheet<int>(
                  context,
                  actions: (context) => [
                    for (var i = 0; i < 8; i++)
                      ListTile(
                        title: Text('Ação número $i com um rótulo longo'),
                        onTap: () => Navigator.of(context).pop(i),
                      ),
                  ],
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        size: const Size(640, 360),
        textScale: 2,
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final last = find.text('Ação número 7 com um rótulo longo');
      await tester.scrollUntilVisible(
        last,
        200,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('AdaptiveButtonRow', () {
    Future<void> pumpRow(WidgetTester tester, Size size, double scale) => _pump(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: AdaptiveButtonRow(
            labels: const ['Minhas publicações', 'Salvos'],
            children: [
              OutlinedButton.icon(
                key: const Key('a'),
                onPressed: () {},
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Minhas publicações'),
              ),
              OutlinedButton.icon(
                key: const Key('b'),
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border_rounded),
                label: const Text('Salvos'),
              ),
            ],
          ),
        ),
      ),
      size: size,
      textScale: scale,
    );

    testWidgets('side by side, equal widths, when the labels fit', (
      tester,
    ) async {
      // Wide enough for the test font, whose glyphs are 1 em squares.
      await pumpRow(tester, const Size(1024, 800), 1);
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(a.top, b.top);
      expect(a.width, closeTo(b.width, 0.01));
    });

    testWidgets('stacked full width instead of breaking a word', (
      tester,
    ) async {
      await pumpRow(tester, const Size(412, 915), 2);
      expect(tester.takeException(), isNull);
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top, greaterThan(a.bottom));
      expect(a.width, 412 - 48);
    });
  });

  group('NeonNavBar labels', () {
    const labels = ['Match', 'Minhas Skills', 'Comunidade', 'Conversas'];

    Future<List<double>> labelScales(
      WidgetTester tester, {
      required Size size,
      required double textScale,
    }) async {
      await _pump(
        tester,
        Scaffold(
          bottomNavigationBar: NeonNavBar(
            items: [
              for (final (i, label) in [...labels, 'Perfil'].indexed)
                NeonNavItem(
                  icon: LineIconShape.star,
                  label: label,
                  selected: i == 0,
                  onTap: () {},
                ),
            ],
          ),
        ),
        size: size,
        textScale: textScale,
      );
      expect(tester.takeException(), isNull);
      return [
        for (final label in [...labels, 'Perfil'])
          tester.widget<Text>(find.text(label)).textScaler!.scale(10) / 10,
      ];
    }

    testWidgets('share one scale, never below the default size', (
      tester,
    ) async {
      final scales = await labelScales(
        tester,
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(scales.toSet(), hasLength(1), reason: 'one size for all');
      expect(scales.first, greaterThanOrEqualTo(1));
    });

    testWidgets('rendered labels fit their slot at one shared size', (
      tester,
    ) async {
      const size = Size(1366, 1024);
      await labelScales(tester, size: size, textScale: 2);
      final slot = size.width / 5 - 4;
      for (final label in [...labels, 'Perfil']) {
        final text = find.text(label);
        final rendered = tester.getRect(text).width;
        expect(rendered, lessThanOrEqualTo(slot + 0.5), reason: label);
        // The shared scale did the fitting: FittedBox only rounds.
        expect(
          rendered / tester.getSize(text).width,
          greaterThan(0.98),
          reason: label,
        );
      }
    });

    testWidgets('follow the system text size when there is room', (
      tester,
    ) async {
      final scales = await labelScales(
        tester,
        // Wide enough for the test font, whose glyphs are 1 em squares.
        size: const Size(1366, 1024),
        textScale: 1.3,
      );
      expect(scales.first, closeTo(1.3, 0.001));
    });
  });

  group('profile header', () {
    const me = UserProfile(
      id: 'me',
      name: 'Ana Carolina Teste de Albuquerque',
      bio: '',
      teach: ['excel'],
      learn: ['design'],
    );

    Future<void> pumpProfile(
      WidgetTester tester,
      Size size,
      double scale, {
      UserProfile me = me,
    }) {
      final db = FakeFirebaseFirestore();
      return tester
          .runAsync(() => ProfileRepository(db).save(me))
          .then(
            (_) => _pump(
              tester,
              ProviderScope(
                overrides: [
                  firestoreProvider.overrideWithValue(db),
                  authStateProvider.overrideWith((ref) => Stream.value('me')),
                  currentProfileProvider.overrideWith(
                    (ref) => Stream.value(me),
                  ),
                ],
                child: const ProfileScreen(),
              ),
              size: size,
              textScale: scale,
            ),
          );
    }

    double nameLeft(WidgetTester tester) =>
        tester.getTopLeft(find.text(me.name)).dx;
    double avatarLeft(WidgetTester tester) =>
        tester.getTopLeft(find.byType(ProfileAvatar).first).dx;

    testWidgets('name beside the photo on a regular phone', (tester) async {
      await pumpProfile(tester, const Size(412, 915), 1);
      expect(nameLeft(tester), greaterThan(avatarLeft(tester) + 72));
    });

    testWidgets('320 dp at normal text keeps the name beside the photo '
        'when its words fit', (tester) async {
      const short = UserProfile(
        id: 'me',
        name: 'Ana Lima Souza',
        bio: '',
        teach: ['excel'],
        learn: ['design'],
      );
      await pumpProfile(tester, const Size(320, 568), 1, me: short);
      expect(
        tester.getTopLeft(find.text(short.name)).dx,
        greaterThan(avatarLeft(tester) + 72),
      );
    });

    testWidgets('name under the photo on 320 dp with 200% text, so its '
        'words are not broken', (tester) async {
      await pumpProfile(tester, const Size(320, 568), 2);
      expect(tester.takeException(), isNull);
      expect(nameLeft(tester), avatarLeft(tester));
      expect(
        tester.getTopLeft(find.text(me.name)).dy,
        greaterThan(tester.getBottomLeft(find.byType(ProfileAvatar).first).dy),
      );
    });
  });
}
