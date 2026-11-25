import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/discover/discover.dart';
import 'package:skill_swap/features/discover/discover_screen.dart';
import 'package:skill_swap/features/discover/knowledge_match.dart';
import 'package:skill_swap/features/discover/swipe_card.dart';
import 'package:skill_swap/features/profile/profile.dart';

// Fictional test data only.
const me = UserProfile(
  id: 'me',
  name: 'Ana Teste',
  bio: '',
  teach: ['excel'],
  learn: ['english'],
);
const bia = UserProfile(
  id: 'bia',
  name: 'Bia Souza',
  bio: 'Professora de inglês.',
  teach: ['english'],
  learn: ['excel'],
);
const davi = UserProfile(
  id: 'davi',
  name: 'Davi Lima',
  bio: '',
  teach: ['english'],
  learn: ['piano'],
);

FirebaseException fsError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

class _FailingDiscover extends DiscoverRepository {
  _FailingDiscover(super.db);

  @override
  Future<List<UserProfile>> fetchCandidates(UserProfile me) async =>
      throw const NetworkFailure();
}

/// Swipes on [failFor] wait for [gate] and then fail; others are stored.
class _SlowFailingDiscover extends DiscoverRepository {
  _SlowFailingDiscover(super.db, {required this.failFor, required this.gate});

  final String failFor;
  final Future<void> gate;

  @override
  Future<bool> swipe({
    required UserProfile me,
    required UserProfile target,
    required bool liked,
  }) async {
    if (target.id != failFor) {
      return super.swipe(me: me, target: target, liked: liked);
    }
    await gate;
    throw const NetworkFailure();
  }
}

void main() {
  group('KnowledgeMatch', () {
    test('exchange when both sides gain', () {
      final m = KnowledgeMatch.between(me, bia)!;
      expect(m.type, KnowledgeMatchType.exchange);
      expect(m.iCanTeach, ['excel']);
      expect(m.iCanLearn, ['english']);
    });

    test('learn when only the other person teaches what I want', () {
      expect(KnowledgeMatch.between(me, davi)!.type, KnowledgeMatchType.learn);
    });

    test('teach when only I teach what they want', () {
      const caio = UserProfile(
        id: 'caio',
        name: 'Caio',
        bio: '',
        teach: ['guitar'],
        learn: ['excel'],
      );
      expect(KnowledgeMatch.between(me, caio)!.type, KnowledgeMatchType.teach);
    });

    test('no connection means no match (never a fake one)', () {
      const eva = UserProfile(
        id: 'eva',
        name: 'Eva',
        bio: '',
        teach: ['piano'],
        learn: ['guitar'],
      );
      expect(KnowledgeMatch.between(me, eva), isNull);
      expect(
        KnowledgeMatch.between(
          me,
          const UserProfile(id: 'x', name: 'X', bio: '', teach: [], learn: []),
        ),
        isNull,
      );
    });
  });

  group('Match screen', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      for (final p in [me, bia, davi]) {
        await ProfileRepository(db).save(p);
      }
    });

    DocumentReference<Map<String, dynamic>> matchDoc(String other) =>
        db.collection('matches').doc((['me', other]..sort()).join('_'));

    Future<void> pumpScreen(
      WidgetTester tester, {
      UserProfile profile = me,
      List<Override> extra = const [],
      Size size = const Size(412, 915),
      double textScale = 1,
      bool reducedMotion = false,
      bool withNavBar = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            authStateProvider.overrideWith((ref) => Stream.value(profile.id)),
            currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
            ...extra,
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            locale: const Locale('pt'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reducedMotion,
              ),
              child: child!,
            ),
            // The real shell's bottom navigation takes about 80 dp.
            home: withNavBar
                ? const Scaffold(
                    body: DiscoverScreen(),
                    bottomNavigationBar: SizedBox(height: 80),
                  )
                : const DiscoverScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Tooltips are excluded from semantics (the button's label is read
    // once), so find the Tooltip widget itself.
    Finder button(String tooltip) =>
        find.byWidgetPredicate((w) => w is Tooltip && w.message == tooltip);

    testWidgets('shows real skills and the knowledge match', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Bia Souza'), findsOneWidget);
      expect(find.text('Professora de inglês.'), findsOneWidget);
      // The card peeking behind also has one, so at least one.
      expect(find.text('Match de Conhecimento'), findsWidgets);
      expect(
        find.text('Você ensina Excel e aprende Inglês com Bia.'),
        findsOneWidget,
      );
      // No invented data: no age, city, verification or level.
      expect(find.textContaining('Iniciante'), findsNothing);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });

    testWidgets('header: logo, notifications not available, profile', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(button('Seu perfil'), findsOneWidget);
      expect(find.bySemanticsLabel('Skill Swap'), findsOneWidget);
      // No notifications feature: no unread dot, and tapping says so.
      await tester.tap(button('Notificações (em breve)'));
      await tester.pump();
      expect(find.text('Notificações (em breve)'), findsWidgets);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('card: goal and affinity come from the real skills', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Bia wants Excel, which I teach; both sides gain: 100 %.
      expect(find.text('Quer aprender'), findsWidgets);
      expect(find.text('Aprender Excel'), findsOneWidget);
      expect(find.text('Afinidade'), findsWidgets);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('info opens the full profile, which can be reported', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(button('Ver detalhes do perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Ensina'), findsOneWidget);
      expect(find.text('Inglês'), findsOneWidget);
      expect(find.text('Afinidade: 100%'), findsOneWidget);

      await tester.tap(find.text('Denunciar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Denunciar Bia Souza'), findsOneWidget);
    });

    testWidgets('approve: animates, records the like, shows next profile', (
      tester,
    ) async {
      // The server refuses the match (no like from Bia yet).
      whenCalling(Invocation.method(#set, null))
          .on(matchDoc('bia'))
          .thenThrow(fsError('permission-denied'));
      await pumpScreen(tester);

      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();

      final like = await db.doc('likes/me_bia').get();
      expect(like.data()?['liked'], isTrue);
      expect(find.text('Deu match!'), findsNothing, reason: 'not mutual');
      expect(find.text('Davi Lima'), findsOneWidget);
      expect(
        find.text('Davi sabe Inglês, que você quer aprender!'),
        findsOneWidget,
      );
    });

    testWidgets('approve accepted by the server shows the match dialog', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();
      expect(find.text('Deu match!'), findsOneWidget);
      await tester.tap(find.text('Continuar explorando'));
      await tester.pumpAndSettle();
      expect(find.text('Davi Lima'), findsOneWidget);
    });

    testWidgets('pass, then undo brings the profile back', (tester) async {
      await pumpScreen(tester);
      final undo = button('Desfazer último pulo');
      expect(
        tester
            .widget<InkWell>(
              find.descendant(of: undo, matching: find.byType(InkWell)),
            )
            .onTap,
        isNull,
        reason: 'nothing to undo yet',
      );

      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      expect((await db.doc('likes/me_bia').get()).data()?['liked'], isFalse);
      expect(find.text('Davi Lima'), findsOneWidget);

      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(find.text('Bia Souza'), findsOneWidget);
    });

    testWidgets('skipping the last card can still be undone', (tester) async {
      await pumpScreen(tester);
      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('Ninguém novo por enquanto'), findsOneWidget);

      await tester.tap(find.text('Desfazer último pulo'));
      await tester.pumpAndSettle();
      expect(find.text('Davi Lima'), findsOneWidget);
    });

    testWidgets('undo is not offered after an approval', (tester) async {
      whenCalling(Invocation.method(#set, null))
          .on(matchDoc('bia'))
          .thenThrow(fsError('permission-denied'));
      await pumpScreen(tester);
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();
      final undo = button('Desfazer último pulo');
      expect(
        tester
            .widget<InkWell>(
              find.descendant(of: undo, matching: find.byType(InkWell)),
            )
            .onTap,
        isNull,
      );
    });

    testWidgets('save is not available yet and says so', (tester) async {
      await pumpScreen(tester);
      await tester.tap(button('Salvar para depois (em breve)'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      // Nothing was stored.
      expect((await db.collection('likes').get()).docs, isEmpty);
      expect(find.text('Bia Souza'), findsOneWidget);
    });

    testWidgets('fast double tap records a single decision', (tester) async {
      whenCalling(Invocation.method(#set, null))
          .on(matchDoc('bia'))
          .thenThrow(fsError('permission-denied'));
      await pumpScreen(tester);
      await tester.tap(button('Tenho interesse'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();

      final likes = await db.collection('likes').get();
      expect(likes.docs.map((d) => d.id), ['me_bia']);
      expect(find.text('Davi Lima'), findsOneWidget);
    });

    testWidgets('drag right approves, short drag snaps back', (tester) async {
      whenCalling(Invocation.method(#set, null))
          .on(matchDoc('bia'))
          .thenThrow(fsError('permission-denied'));
      await pumpScreen(tester);

      await tester.drag(find.text('Bia Souza'), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(find.text('Bia Souza'), findsOneWidget, reason: 'too short');
      expect((await db.doc('likes/me_bia').get()).exists, isFalse);

      await tester.drag(find.text('Bia Souza'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect((await db.doc('likes/me_bia').get()).data()?['liked'], isTrue);
    });

    testWidgets('network failure keeps the card and explains', (tester) async {
      whenCalling(Invocation.method(#set, null))
          .on(db.doc('likes/me_bia'))
          .thenThrow(fsError('unavailable'));
      await pumpScreen(tester);
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sem conexão'), findsOneWidget);
      expect(find.text('Bia Souza'), findsOneWidget);
    });

    testWidgets('expired session / permission error is reported, no crash', (
      tester,
    ) async {
      whenCalling(Invocation.method(#set, null))
          .on(db.doc('likes/me_bia'))
          .thenThrow(fsError('unauthenticated'));
      await pumpScreen(tester);
      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      expect(find.textContaining('permissão'), findsOneWidget);
      expect(find.text('Bia Souza'), findsOneWidget);
    });

    testWidgets('load failure shows retry', (tester) async {
      await pumpScreen(
        tester,
        extra: [
          discoverRepositoryProvider.overrideWithValue(_FailingDiscover(db)),
        ],
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('empty deck shows the empty state', (tester) async {
      await ProfileRepository(db).save(
        const UserProfile(
          id: 'me',
          name: 'Ana',
          bio: '',
          teach: ['excel'],
          learn: ['chemistry'],
        ),
      );
      await pumpScreen(
        tester,
        profile: const UserProfile(
          id: 'me',
          name: 'Ana',
          bio: '',
          teach: ['excel'],
          learn: ['chemistry'],
        ),
      );
      expect(find.text('Ninguém novo por enquanto'), findsOneWidget);
    });

    testWidgets('no connection and no skills: no banner, no crash', (
      tester,
    ) async {
      const lonely = UserProfile(
        id: 'me',
        name: 'Ana',
        bio: '',
        teach: [],
        learn: [],
      );
      db = FakeFirebaseFirestore();
      await ProfileRepository(db).save(lonely);
      await ProfileRepository(db).save(
        const UserProfile(
          id: 'eva',
          name: 'Eva',
          bio: '',
          teach: [],
          learn: [],
        ),
      );
      await pumpScreen(tester, profile: lonely);
      expect(find.text('Eva'), findsOneWidget);
      expect(find.text('Match de Conhecimento'), findsNothing);
    });

    testWidgets('long texts at 320 dp and 200% text do not overflow', (
      tester,
    ) async {
      await ProfileRepository(db).save(
        UserProfile(
          id: 'bia',
          name: 'B' * 40,
          bio: 'x ' * 80,
          teach: const ['english', 'spanish', 'programming', 'python', 'math'],
          learn: const ['excel', 'guitar', 'piano', 'drawing', 'writing'],
        ),
      );
      await pumpScreen(
        tester,
        size: const Size(320, 640),
        textScale: 2,
        withNavBar: true,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('B' * 40), findsOneWidget);
    });

    testWidgets('tablet/desktop: the deck keeps phone proportions', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(1280, 800));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SwipeCard)).width, lessThan(440));
    });

    testWidgets('landscape phone: deck scrolls instead of collapsing', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(915, 412), withNavBar: true);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SwipeCard)).height, greaterThan(300));
      await tester.ensureVisible(button('Pular'));
      await tester.pumpAndSettle();
      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      expect((await db.doc('likes/me_bia').get()).data()?['liked'], isFalse);
    });

    testWidgets('reduced motion: approve and undo still work', (tester) async {
      whenCalling(Invocation.method(#set, null))
          .on(matchDoc('bia'))
          .thenThrow(fsError('permission-denied'));
      await pumpScreen(tester, reducedMotion: true);
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();
      expect((await db.doc('likes/me_bia').get()).data()?['liked'], isTrue);

      await tester.tap(button('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('Ninguém novo por enquanto'), findsOneWidget);
      await tester.tap(find.text('Desfazer último pulo'));
      await tester.pumpAndSettle();
      expect(find.text('Davi Lima'), findsOneWidget);
    });

    testWidgets('one card node: label and swipe actions together; the '
        'waiting card is hidden from screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);
      expect(find.bySemanticsLabel(RegExp('^Perfil de Davi')), findsNothing);

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Perfil de Bia Souza')),
      );
      final pass = CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Pular'),
      );
      expect(
        node.getSemanticsData().customSemanticsActionIds,
        containsAll([
          pass,
          CustomSemanticsAction.getIdentifier(
            const CustomSemanticsAction(label: 'Tenho interesse'),
          ),
        ]),
      );
      node.owner!.performAction(node.id, SemanticsAction.customAction, pass);
      await tester.pumpAndSettle();
      expect((await db.doc('likes/me_bia').get()).data()?['liked'], isFalse);
      handle.dispose();
    });

    testWidgets('a failed like never drops the decision on the next card', (
      tester,
    ) async {
      final failBia = Completer<void>();
      await pumpScreen(
        tester,
        extra: [
          discoverRepositoryProvider.overrideWithValue(
            _SlowFailingDiscover(db, failFor: 'bia', gate: failBia.future),
          ),
        ],
      );
      // Approve Bia: her write hangs; Davi becomes the top card.
      await tester.tap(button('Tenho interesse'));
      await tester.pumpAndSettle();
      expect(find.text('Bia Souza'), findsNothing);

      // Start skipping Davi, then Bia's write fails mid-animation.
      await tester.tap(button('Pular'));
      await tester.pump(const Duration(milliseconds: 50));
      failBia.completeError(const NetworkFailure());
      await tester.pumpAndSettle();

      // Davi's skip was recorded and stays undoable; Bia came back.
      expect((await db.doc('likes/me_davi').get()).data()?['liked'], isFalse);
      expect(find.textContaining('Sem conexão'), findsOneWidget);
      expect(find.text('Bia Souza'), findsOneWidget);
      final undo = button('Desfazer último pulo');
      expect(
        tester
            .widget<InkWell>(
              find.descendant(of: undo, matching: find.byType(InkWell)),
            )
            .onTap,
        isNotNull,
      );
    });

    testWidgets('accessibility: tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(
        find.bySemanticsLabel(RegExp('^Perfil de Bia Souza')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
