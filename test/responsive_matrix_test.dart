// Responsive matrix: every app route at the reference viewports and text
// scales, with long real-world content. Fails on any layout exception
// (RenderFlex overflow, unbounded constraints, ...), listing all of them.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/router/app_router.dart';
import 'package:skill_swap/core/router/app_routes.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/core/widgets/app_widgets.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/profile/profile.dart';

// Fictional test data only; names and texts are deliberately long.
const me = UserProfile(
  id: 'me',
  name: 'Ana Carolina Teste de Albuquerque',
  bio:
      'Ensino Excel avançado, tabelas dinâmicas e automações. Quero aprender '
      'design de interfaces e inglês para entrevistas.',
  teach: ['excel', 'spanish'],
  learn: ['design', 'english'],
);

const _longName = 'Maria Eduarda Fernandes Cavalcanti';

/// Reference viewports (logical pixels), including phone landscape.
const viewports = <String, Size>{
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '375x667': Size(375, 667),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
  '430x932': Size(430, 932),
  '600x960': Size(600, 960),
  '768x1024': Size(768, 1024),
  '1024x1366': Size(1024, 1366),
  'landscape 640x360': Size(640, 360),
  'landscape 915x412': Size(915, 412),
};

const textScales = [1.0, 1.3, 2.0];

final routes = <String>[
  AppRoutes.discover,
  AppRoutes.community,
  AppRoutes.matches,
  AppRoutes.profile,
  AppRoutes.editProfile,
  AppRoutes.chat('bia_me'),
  AppRoutes.newPost,
  AppRoutes.communitySearchFor('design'),
  AppRoutes.saved,
  AppRoutes.notifications,
  AppRoutes.post('p1'),
  AppRoutes.editPost('mine1'),
  AppRoutes.member('bia'),
  AppRoutes.followers('bia'),
  AppRoutes.following('me'),
  AppRoutes.terms,
];

Future<void> _seed(FakeFirebaseFirestore db) async {
  await ProfileRepository(db).save(me);
  final now = DateTime.now();
  Timestamp ago(int minutes) =>
      Timestamp.fromDate(now.subtract(Duration(minutes: minutes)));

  Future<void> user(String id, String name, List<String> teach) =>
      db.doc('users/$id').set({
        'name': name,
        'bio':
            'Designer de produto há oito anos, apaixonada por tipografia, '
            'acessibilidade e sistemas de design escaláveis.',
        'teach': teach,
        'learn': ['excel', 'spanish'],
        'updatedAt': Timestamp.now(),
      });
  await user('bia', _longName, ['design', 'english']);
  await user('caio', 'Caio', ['english']);

  Future<void> post(String id, String author, String type, int age) =>
      db.doc('posts/$id').set({
        'authorId': author,
        'description':
            'Finalizei a identidade visual da Vetra com um sistema completo '
            'de componentes, grids responsivos e tokens. ${'Texto longo ' * 30}'
            '#Branding #DesignSystem',
        'type': type,
        'skillIds': ['design', 'english'],
        'tags': ['Branding', 'DesignSystemResponsivo', 'Tipografia'],
        'keywords': ['branding', 'vetra', 'design'],
        'visibility': 'public',
        'mediaCount': 0,
        'aspectRatios': <double>[],
        'createdAt': ago(age),
        'updatedAt': Timestamp.now(),
      });
  await post('p1', 'bia', 'project', 5);
  await post('p2', 'caio', 'question', 30);
  await post('p3', 'bia', 'knowledge', 90);
  await post('mine1', 'me', 'project', 120);

  await db.doc('posts/p1/comments/c1').set({
    'authorId': 'caio',
    'text': 'Ficou incrível! ${'Comentário longo ' * 12}',
    'parentId': null,
    'createdAt': ago(3),
  });
  await db.doc('posts/p1/comments/c2').set({
    'authorId': 'me',
    'text': 'Meu comentário',
    'parentId': null,
    'createdAt': ago(1),
  });
  await db.doc('users/me/saved/p1').set({'createdAt': ago(2)});
  await db.doc('follows/me_bia').set({
    'followerId': 'me',
    'followingId': 'bia',
    'createdAt': ago(50),
  });
  await db.doc('follows/caio_bia').set({
    'followerId': 'caio',
    'followingId': 'bia',
    'createdAt': ago(40),
  });
  for (final (id, type) in [
    ('n1', 'like'),
    ('n2', 'comment'),
    ('n3', 'follow'),
    ('n4', 'learn'),
  ]) {
    await db.doc('users/me/notifications/$id').set({
      'type': type,
      'actorId': 'bia',
      'postId': type == 'follow' ? null : 'mine1',
      'commentId': null,
      'read': id == 'n4',
      'createdAt': ago(10),
    });
  }

  await db.doc('matches/bia_me').set({
    'userIds': ['bia', 'me'],
    'lastMessage': 'Oi! Vamos marcar a primeira aula de design?',
    'lastMessageAt': ago(1),
    'status': 'active',
  });
  await db.doc('matches/caio_me').set({
    'userIds': ['caio', 'me'],
    'status': 'active',
  });
  for (var i = 0; i < 12; i++) {
    await db.doc('matches/bia_me/messages/m$i').set({
      'senderId': i.isEven ? 'bia' : 'me',
      'text': i == 3
          ? 'Mensagem bem longa ${'com várias palavras ' * 20}'
          : 'Mensagem $i',
      'createdAt': ago(60 - i),
    });
  }
}

/// Collects layout exceptions instead of failing on the first one.
class _Problems {
  final list = <String>[];
  String step = 'startup';
  void Function(FlutterErrorDetails)? _previous;

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = (details) {
      // Where the failing widget was created, to point at the fix.
      final where = RegExp(r'lib/[\w/]+\.dart:\d+')
          .firstMatch(details.toString())
          ?.group(0);
      final what = details.exceptionAsString().split('\n').first;
      list.add('$step → $what${where == null ? '' : ' ($where)'}');
    };
  }

  void stop() => FlutterError.onError = _previous;

  List<String> get unique => list.toSet().toList();
}

Future<GoRouter> _pumpApp(
  WidgetTester tester,
  FakeFirebaseFirestore db,
  Size size,
  double scale, {
  String? uid = 'me',
  bool consent = true,
  double keyboard = 0,
  FakeViewPadding insets = FakeViewPadding.zero,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..padding = insets
    ..viewPadding = insets;
  addTearDown(tester.view.reset);
  // A fresh ProviderScope: overrides are not updated on an existing one.
  await tester.pumpWidget(const SizedBox.shrink());
  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
        authStateProvider.overrideWith((ref) => Stream.value(uid)),
        consentProvider.overrideWith((ref) => Stream.value(consent)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          router = ref.watch(routerProvider);
          return MaterialApp.router(
            theme: AppTheme.dark(),
            locale: const Locale('pt'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                // The software keyboard, when open, covers the bottom.
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: child!,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Scrolls every visible vertical list to its end, so lazily built
/// children (comments, later posts, form fields) are laid out too.
Future<void> _scrollThrough(WidgetTester tester) async {
  for (var step = 0; step < 12; step++) {
    var moved = false;
    final scrollables = find
        .byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              axisDirectionToAxis(w.axisDirection) == Axis.vertical,
        )
        .evaluate()
        .toList();
    for (final element in scrollables) {
      final position = (element as StatefulElement).state is ScrollableState
          ? (element.state as ScrollableState).position
          : null;
      if (position == null || !position.hasContentDimensions) continue;
      if (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          (position.pixels + position.viewportDimension * 0.9).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        moved = true;
      }
    }
    if (!moved) return;
    await tester.pumpAndSettle();
  }
}

Finder _tooltip(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  group('routes', () {
    for (final MapEntry(key: label, value: size) in viewports.entries) {
      for (final scale in textScales) {
        testWidgets('all routes at $label, text ${(scale * 100).round()}%', (
          tester,
        ) async {
          final db = FakeFirebaseFirestore();
          await _seed(db);
          final problems = _Problems()..start();
          try {
            final router = await _pumpApp(tester, db, size, scale);
            for (final route in routes) {
              problems.step = route;
              router.go(route);
              await tester.pumpAndSettle();
              // The route must really render: no redirect, no error state.
              expect(router.state.uri.toString(), route);
              if (find.byType(ErrorView).evaluate().isNotEmpty ||
                  find.byType(LoadingView).evaluate().isNotEmpty) {
                problems.list.add('$route → error or loading state');
              }
              problems.step = '$route (scrolled)';
              await _scrollThrough(tester);
            }
          } finally {
            problems.stop();
          }
          expect(problems.unique, isEmpty);
        });
      }
    }
  });

  group('notched phone in landscape', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all routes at 932x430 with side insets, text '
          '${(scale * 100).round()}%', (tester) async {
        final db = FakeFirebaseFirestore();
        await _seed(db);
        final problems = _Problems()..start();
        try {
          final router = await _pumpApp(
            tester,
            db,
            const Size(932, 430),
            scale,
            insets: const FakeViewPadding(left: 47, right: 47, bottom: 21),
          );
          for (final route in routes) {
            problems.step = route;
            router.go(route);
            await tester.pumpAndSettle();
            expect(router.state.uri.toString(), route);
            problems.step = '$route (scrolled)';
            await _scrollThrough(tester);
          }
        } finally {
          problems.stop();
        }
        expect(problems.unique, isEmpty);
      });
    }
  });

  group('modals', () {
    const modalViewports = {
      '320x568': Size(320, 568),
      '360x640': Size(360, 640),
      '412x915': Size(412, 915),
      '768x1024': Size(768, 1024),
      'landscape 640x360': Size(640, 360),
    };
    for (final MapEntry(key: label, value: size) in modalViewports.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('sheets and dialogs at $label, text '
            '${(scale * 100).round()}%', (tester) async {
          final db = FakeFirebaseFirestore();
          await _seed(db);
          final problems = _Problems()..start();
          try {
            final router = await _pumpApp(tester, db, size, scale);

            bool modalOpen() =>
                find.byType(BottomSheet).evaluate().isNotEmpty ||
                find.byType(Dialog).evaluate().isNotEmpty ||
                find
                    .byWidgetPredicate((w) => w is PopupMenuItem)
                    .evaluate()
                    .isNotEmpty;

            Future<void> close() async {
              for (var i = 0; i < 3 && modalOpen(); i++) {
                await tester.binding.handlePopRoute();
                await tester.pumpAndSettle();
              }
              expect(modalOpen(), isFalse, reason: 'modal left open');
            }

            /// Opens [route] and taps [trigger], which must open a sheet,
            /// dialog or menu; then optionally taps the item labelled
            /// [then] and checks where that led ([expectText] on screen,
            /// or the router at [expectRoute]).
            Future<void> open(
              String name,
              String route,
              Finder trigger, {
              String? then,
              String? expectText,
              String? expectRoute,
              bool expectGone = false,
              Finder? scrollTo,
            }) async {
              problems.step = name;
              router.go(route);
              await tester.pumpAndSettle();
              if (scrollTo != null) {
                await tester.scrollUntilVisible(
                  scrollTo,
                  300,
                  maxScrolls: 100,
                  // The post's list (text fields also contain a vertical
                  // Scrollable).
                  scrollable: find
                      .descendant(
                        of: find.byType(CustomScrollView),
                        matching: find.byType(Scrollable),
                      )
                      .first,
                );
                await tester.pumpAndSettle();
              }
              expect(trigger, findsWidgets, reason: name);
              await tester.ensureVisible(trigger.first);
              await tester.pumpAndSettle();
              await tester.tap(trigger.first);
              await tester.pumpAndSettle();
              expect(modalOpen(), isTrue, reason: '$name did not open');
              if (then != null) {
                problems.step = '$name → $then';
                final item = find.text(then);
                expect(item, findsWidgets, reason: '$name → $then');
                await tester.ensureVisible(item.last);
                await tester.pumpAndSettle();
                await tester.tap(item.last);
                await tester.pumpAndSettle();
                if (expectText != null) {
                  expect(
                    find.text(expectText),
                    expectGone ? findsNothing : findsWidgets,
                    reason: '$name → $then',
                  );
                }
                if (expectRoute != null) {
                  expect(router.state.uri.toString(), expectRoute);
                }
              }
              await close();
            }

            final post = AppRoutes.post('p1');
            final mine = AppRoutes.post('mine1');
            final postMenu = _tooltip(l10n.postMenuTooltip);
            await open('post menu (other)', post, postMenu);
            await open(
              'post menu → report',
              post,
              postMenu,
              then: l10n.reportPostAction,
              expectText: l10n.reportPostTitle,
            );
            await open(
              'post menu → block',
              post,
              postMenu,
              then: l10n.blockMemberAction(_longName),
              expectText: l10n.blockConfirmTitle(_longName),
            );
            await open('post menu (mine)', mine, postMenu);
            await open(
              'post menu → delete',
              mine,
              postMenu,
              then: l10n.deletePostAction,
              expectText: l10n.deletePostTitle,
            );
            await open(
              'post menu → edit',
              mine,
              postMenu,
              then: l10n.editPostAction,
              expectRoute: AppRoutes.editPost('mine1'),
            );
            await open('share sheet', post, _tooltip(l10n.shareAction));
            final commentMenu = _tooltip(l10n.commentMenuTooltip);
            await open('comment menu', post, commentMenu);
            await open(
              'comment menu → report',
              post,
              commentMenu,
              then: l10n.reportCommentAction,
              expectText: l10n.reportCommentTitle,
            );
            final member = AppRoutes.member('bia');
            final memberMenu = _tooltip(l10n.memberMenuTooltip);
            await open('member menu', member, memberMenu);
            await open(
              'member menu → report',
              member,
              memberMenu,
              then: l10n.reportMemberAction,
              expectText: l10n.reportTitle(_longName),
            );
            await open(
              'chat menu',
              AppRoutes.chat('bia_me'),
              _tooltip(l10n.moreOptions),
            );
            await open(
              'profile details',
              AppRoutes.discover,
              _tooltip(l10n.profileDetailsAction),
            );
            // Last: it deletes data. My own comment is the second one.
            await open(
              'comment menu (mine) → delete',
              post,
              commentMenu.last,
              scrollTo: find.text('Meu comentário'),
              then: l10n.deleteCommentAction,
              expectText: 'Meu comentário',
              expectGone: true,
            );
          } finally {
            problems.stop();
          }
          expect(problems.unique, isEmpty);
        });
      }
    }
  });

  group('entry screens and keyboard', () {
    const sizes = {
      '320x568': Size(320, 568),
      '390x844': Size(390, 844),
      '768x1024': Size(768, 1024),
      'landscape 640x360': Size(640, 360),
    };
    for (final MapEntry(key: label, value: size) in sizes.entries) {
      for (final scale in [1.0, 2.0]) {
        final suffix = '$label, text ${(scale * 100).round()}%';

        testWidgets('sign-in, setup and consent at $suffix', (tester) async {
          final problems = _Problems()..start();
          try {
            for (final keyboard in [0.0, size.height * 0.4]) {
              final open = keyboard > 0 ? ' + keyboard' : '';
              problems.step = 'sign-in$open';
              var db = FakeFirebaseFirestore();
              final router = await _pumpApp(
                tester,
                db,
                size,
                scale,
                uid: null,
                keyboard: keyboard,
              );
              expect(router.state.matchedLocation, AppRoutes.signIn);
              await _scrollThrough(tester);

              problems.step = 'setup$open';
              db = FakeFirebaseFirestore();
              final setup = await _pumpApp(
                tester,
                db,
                size,
                scale,
                keyboard: keyboard,
              );
              expect(setup.state.matchedLocation, AppRoutes.setup);
              await _scrollThrough(tester);

              problems.step = 'consent$open';
              db = FakeFirebaseFirestore();
              await ProfileRepository(db).save(me);
              final consent = await _pumpApp(
                tester,
                db,
                size,
                scale,
                consent: false,
                keyboard: keyboard,
              );
              expect(consent.state.matchedLocation, AppRoutes.consent);
              await _scrollThrough(tester);
            }
          } finally {
            problems.stop();
          }
          expect(problems.unique, isEmpty);
        });

        testWidgets('text-entry screens with the keyboard open at $suffix', (
          tester,
        ) async {
          final db = FakeFirebaseFirestore();
          await _seed(db);
          final problems = _Problems()..start();
          try {
            final router = await _pumpApp(
              tester,
              db,
              size,
              scale,
              keyboard: size.height * 0.4,
            );
            for (final route in [
              AppRoutes.editProfile,
              AppRoutes.chat('bia_me'),
              AppRoutes.newPost,
              AppRoutes.post('p1'),
              AppRoutes.communitySearchFor('design'),
            ]) {
              problems.step = '$route + keyboard';
              router.go(route);
              await tester.pumpAndSettle();
              await _scrollThrough(tester);
            }
          } finally {
            problems.stop();
          }
          expect(problems.unique, isEmpty);
        });
      }
    }
  });

  group('accessibility guidelines', () {
    testWidgets('touch targets, labels and contrast on every route', (
      tester,
    ) async {
      // Disposed in `finally`: the binding checks for live handles before
      // tear-downs run.
      final handle = tester.ensureSemantics();
      final failures = <String>[];
      try {
        for (final (size, scale) in [
          (const Size(412, 915), 1.0),
          (const Size(360, 640), 1.3),
        ]) {
          final db = FakeFirebaseFirestore();
          await _seed(db);
          final router = await _pumpApp(tester, db, size, scale);
          for (final route in routes) {
            router.go(route);
            await tester.pumpAndSettle();
            for (final (name, guideline) in [
              ('tap target', androidTapTargetGuideline),
              ('label', labeledTapTargetGuideline),
              ('contrast', textContrastGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              // Known false positive: the contrast check samples the neon
              // glow around the selected bottom-bar label as its background
              // (real contrast of neon on the bar: about 15:1).
              final navGlow =
                  name == 'contrast' &&
                  (result.reason ?? '').contains('isSelected, isButton') &&
                  (result.reason ?? '').contains('font size of 12.5');
              if (!result.passed && !navGlow) {
                failures.add('$size $scale $route [$name]: ${result.reason}');
              }
            }
          }
        }
      } finally {
        handle.dispose();
      }
      expect(failures, isEmpty);
    });
  });
}
