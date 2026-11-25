import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/router/app_router.dart';
import 'package:skill_swap/core/router/app_routes.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/community/community_providers.dart';
import 'package:skill_swap/features/community/community_repository.dart';
import 'package:skill_swap/features/community/presentation/community_screen.dart';
import 'package:skill_swap/features/community/presentation/community_widgets.dart';
import 'package:skill_swap/features/community/presentation/post_composer_screen.dart';
import 'package:skill_swap/features/community/presentation/post_detail_screen.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/matches/matches_screen.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/profile/profile_screen.dart';

// Fictional test data only.
const me = UserProfile(
  id: 'me',
  name: 'Ana Teste',
  bio: 'Ensino Excel.',
  teach: ['excel'],
  learn: ['design'],
);

FirebaseException fsError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

Future<void> seedUser(
  FakeFirebaseFirestore db,
  String id,
  String name, {
  List<String> teach = const ['design'],
}) => db.doc('users/$id').set({
  'name': name,
  'bio': '',
  'teach': teach,
  'learn': ['excel'],
  'updatedAt': Timestamp.now(),
});

Future<void> seedPost(
  FakeFirebaseFirestore db,
  String id, {
  String author = 'bia',
  String text = 'Finalizei a identidade visual da Vetra',
  List<String> skills = const ['design'],
  String type = 'project',
  int ageMinutes = 5,
}) => db.doc('posts/$id').set({
  'authorId': author,
  'description': text,
  'type': type,
  'skillIds': skills,
  'tags': ['Branding'],
  'keywords': ['branding', 'vetra'],
  'visibility': 'public',
  'mediaCount': 0,
  'aspectRatios': <double>[],
  'createdAt': Timestamp.fromDate(
    DateTime.now().subtract(Duration(minutes: ageMinutes)),
  ),
  'updatedAt': Timestamp.now(),
});

/// First page works; every next page fails (counts the attempts).
class _FailingNextPage extends CommunityRepository {
  _FailingNextPage(super.db);

  int nextPageCalls = 0;

  @override
  Future<PostPage> fetchPage(
    PostQuery query, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 10,
  }) {
    if (cursor == null) return super.fetchPage(query, limit: limit);
    nextPageCalls++;
    return Future.error(const NetworkFailure());
  }
}

class _FailingPosts extends CommunityRepository {
  _FailingPosts(super.db);

  @override
  Future<PostPage> fetchPage(
    PostQuery query, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 10,
  }) => Future.error(const PermissionFailure());
}

void main() {
  late FakeFirebaseFirestore db;
  late StreamController<List<Match>> matches;
  late GoRouter router;

  setUp(() async {
    db = FakeFirebaseFirestore();
    matches = StreamController<List<Match>>.broadcast();
    await ProfileRepository(db).save(me);
    await seedUser(db, 'bia', 'Bia Lima');
  });

  tearDown(() => matches.close());

  Future<void> pumpApp(
    WidgetTester tester, {
    String location = AppRoutes.community,
    Size size = const Size(412, 915),
    double textScale = 1,
    List<Match> initialMatches = const [],
    CommunityRepository? posts,
    ImagesPicker? picker,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          authStateProvider.overrideWith((ref) => Stream.value('me')),
          currentProfileProvider.overrideWith((ref) => Stream.value(me)),
          consentProvider.overrideWith((ref) => Stream.value(true)),
          matchesProvider.overrideWith((ref) async* {
            yield initialMatches;
            yield* matches.stream;
          }),
          if (posts != null)
            communityRepositoryProvider.overrideWithValue(posts),
          if (picker != null)
            postImagesPickerProvider.overrideWithValue(picker),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: MaterialApp.router(
                theme: AppTheme.dark(),
                locale: const Locale('pt'),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go(location);
    await tester.pumpAndSettle();
  }

  Finder semantics(Pattern label) => find.bySemanticsLabel(label);

  group('navigation', () {
    testWidgets('five tabs, Comunidade in the middle; state kept between '
        'tabs', (tester) async {
      await seedPost(db, 'p1');
      await pumpApp(tester, location: AppRoutes.discover);

      final labels = [
        'Match',
        'Minhas Skills',
        'Comunidade',
        'Conversas',
        'Perfil',
      ];
      final xs = [
        for (final l in labels) tester.getCenter(find.text(l).last).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()), reason: 'left to right');

      await tester.tap(find.text('Comunidade').last);
      await tester.pumpAndSettle();
      expect(find.byType(CommunityScreen), findsOneWidget);
      expect(find.text('Compartilhe, aprenda e inspire.'), findsOneWidget);
      expect(find.textContaining('identidade visual'), findsOneWidget);

      // Choose a filter, visit the other tabs, come back: still selected.
      await tester.ensureVisible(find.text('Projetos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conversas').last);
      await tester.pumpAndSettle();
      expect(find.byType(MatchesScreen), findsOneWidget);
      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.text('Comunidade').last);
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Projetos'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
      await tester.tap(find.text('Match').last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.discover);
    });

    testWidgets('320 dp and 200% text: feed and bar without overflow', (
      tester,
    ) async {
      await seedPost(db, 'p1', text: 'Texto longo ' * 40);
      await pumpApp(tester, size: const Size(320, 640), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(CommunityScreen), findsOneWidget);
    });
  });

  group('feed', () {
    testWidgets('loads the first page and paginates while scrolling', (
      tester,
    ) async {
      for (var i = 0; i < 13; i++) {
        await seedPost(db, 'p$i', text: 'post número $i', ageMinutes: 100 - i);
      }
      await pumpApp(tester);
      expect(find.text('post número 12'), findsOneWidget);
      // Hashtags are pills sized to their text, not full-width bars.
      expect(
        tester.getSize(find.byType(HashtagChip).first).width,
        lessThan(200),
      );
      await tester.scrollUntilVisible(
        find.text('post número 0'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('post número 0'), findsOneWidget);
      expect(find.text('Você viu tudo por enquanto'), findsOneWidget);
    });

    testWidgets('empty state invites to publish', (tester) async {
      await pumpApp(tester);
      expect(find.text('Nenhuma publicação ainda'), findsOneWidget);
      expect(find.text('Nova publicação'), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      await pumpApp(tester, posts: _FailingPosts(db));
      expect(find.text('Algo deu errado'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('following tab without follows explains what to do', (
      tester,
    ) async {
      await seedPost(db, 'p1');
      await pumpApp(tester);
      await tester.tap(find.text('Seguindo'));
      await tester.pumpAndSettle();
      expect(find.text('Nada de quem você segue'), findsOneWidget);
    });

    testWidgets('posts of blocked people are hidden', (tester) async {
      await seedPost(db, 'p1', text: 'post da Bia');
      await seedUser(db, 'caio', 'Caio');
      await seedPost(db, 'p2', author: 'caio', text: 'post do Caio');
      await db.doc('blocks/me_bia').set({'blocker': 'me', 'blocked': 'bia'});
      await pumpApp(tester);
      expect(find.text('post da Bia'), findsNothing);
      expect(find.text('post do Caio'), findsOneWidget);
    });
  });

  group('review regressions', () {
    testWidgets('a failing next page is not retried in a loop', (tester) async {
      for (var i = 0; i < 12; i++) {
        await seedPost(db, 'p$i', text: 'post número $i', ageMinutes: 100 - i);
      }
      final posts = _FailingNextPage(db);
      await pumpApp(tester, posts: posts);
      await tester.scrollUntilVisible(
        find.text('post número 2'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(posts.nextPageCalls, 1, reason: 'no automatic retry loop');
      expect(
        find.text('Não foi possível carregar mais. Toque para tentar de novo'),
        findsOneWidget,
      );
    });

    testWidgets('deleting from the detail goes back and confirms', (
      tester,
    ) async {
      await seedPost(db, 'mine', author: 'me', text: 'meu post');
      await pumpApp(tester);
      router.push(AppRoutes.post('mine')).ignore();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opções da publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir publicação').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect((await db.doc('posts/mine').get()).exists, isFalse);
      expect(find.text('Publicação excluída'), findsOneWidget);
      expect(find.byType(PostDetailScreen), findsNothing);
      expect(find.text('meu post'), findsNothing, reason: 'gone from the feed');
    });

    testWidgets('blocking confirms with a message', (tester) async {
      await seedPost(db, 'p1');
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Opções da publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear Bia Lima'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Perfil bloqueado'), findsOneWidget);
    });
  });

  group('interactions', () {
    testWidgets('like and unlike (optimistic, persisted, one per member)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await seedPost(db, 'p1');
      await pumpApp(tester);
      await tester.tap(semantics(RegExp(r'^Curtir')));
      await tester.pumpAndSettle();
      expect((await db.doc('posts/p1/likes/me').get()).exists, isTrue);
      expect(semantics(RegExp(r'^Descurtir, 1 curtida')), findsOneWidget);

      await tester.tap(semantics(RegExp(r'^Descurtir')));
      await tester.pumpAndSettle();
      expect((await db.doc('posts/p1/likes/me').get()).exists, isFalse);
      expect(semantics(RegExp(r'^Curtir, nenhuma curtida')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failed like is reverted and explained', (tester) async {
      final handle = tester.ensureSemantics();
      await seedPost(db, 'p1');
      whenCalling(Invocation.method(#set, null))
          .on(db.doc('posts/p1/likes/me'))
          .thenThrow(fsError('permission-denied'));
      await pumpApp(tester);
      await tester.tap(semantics(RegExp(r'^Curtir')));
      await tester.pumpAndSettle();
      expect(semantics(RegExp(r'^Curtir, nenhuma curtida')), findsOneWidget);
      expect(
        find.text('Você não tem permissão para esta ação.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('save and see it in Salvos', (tester) async {
      await seedPost(db, 'p1', text: 'post para salvar');
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Salvar'));
      await tester.pumpAndSettle();
      expect((await db.doc('users/me/saved/p1').get()).exists, isTrue);
      unawaited(router.push(AppRoutes.saved));
      await tester.pumpAndSettle();
      expect(find.text('post para salvar'), findsOneWidget);
    });

    testWidgets('comment on a post and reply', (tester) async {
      await seedPost(db, 'p1');
      await pumpApp(tester, location: AppRoutes.post('p1'));
      expect(find.byType(PostDetailScreen), findsOneWidget);
      expect(
        find.text('Nenhum comentário ainda. Comece a conversa!'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Ficou incrível!');
      await tester.pump();
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('Ficou incrível!'), findsOneWidget);
      final comments = await db.collection('posts/p1/comments').get();
      expect(comments.docs.single.data()['authorId'], 'me');
    });

    testWidgets('report a post (reason required) creates a report', (
      tester,
    ) async {
      await seedPost(db, 'p1');
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Opções da publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Denunciar publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar denúncia').last);
      await tester.pumpAndSettle();
      expect(find.text('Escolha um motivo'), findsOneWidget);
      await tester.tap(find.text('Golpe'));
      await tester.tap(find.text('Enviar denúncia').last);
      await tester.pumpAndSettle();
      final report = (await db.collection('reports').get()).docs.single.data();
      expect(report['targetType'], 'post');
      expect(report['postId'], 'p1');
      expect(report['reason'], 'scam');
      expect(report['reportedId'], 'bia');
    });

    testWidgets('block from the post menu hides the author', (tester) async {
      await seedPost(db, 'p1', text: 'post da Bia');
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Opções da publicação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear Bia Lima'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquear').last);
      await tester.pumpAndSettle();
      expect((await db.doc('blocks/me_bia').get()).exists, isTrue);
      expect(find.text('post da Bia'), findsNothing);
    });

    testWidgets('follow and unfollow from the profile', (tester) async {
      await pumpApp(tester, location: AppRoutes.member('bia'));
      expect(find.text('Bia Lima'), findsWidgets);
      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();
      expect((await db.doc('follows/me_bia').get()).exists, isTrue);
      expect(find.text('Seguindo'), findsWidgets);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Seguindo'));
      await tester.pumpAndSettle();
      expect((await db.doc('follows/me_bia').get()).exists, isFalse);
    });
  });

  group('Match integration', () {
    testWidgets('"Quero aprender" sends interest through Match once', (
      tester,
    ) async {
      await seedPost(db, 'p1');
      // No mutual interest yet: the rules refuse the match.
      whenCalling(Invocation.method(#set, null))
          .on(db.doc('matches/${Match.pairId('me', 'bia')}'))
          .thenThrow(fsError('permission-denied'));
      await pumpApp(tester);
      expect(find.text('Habilidade disponível para ensinar'), findsOneWidget);
      await tester.tap(find.text('Quero aprender com Bia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar interesse'));
      await tester.pumpAndSettle();

      final like = await db.doc('likes/me_bia').get();
      expect(like.data()!['liked'], isTrue);
      final note = await db.doc('users/bia/notifications/learn_me').get();
      expect(note.data()!['postId'], 'p1');
      expect(
        find.text('Interesse enviado · aguardando resposta'),
        findsOneWidget,
      );
      expect(
        find.text('Quero aprender com Bia'),
        findsNothing,
        reason: 'no duplicate request',
      );
    });

    testWidgets('mutual interest: match dialog and chat', (tester) async {
      await seedPost(db, 'p1');
      await pumpApp(tester);
      await tester.tap(find.text('Quero aprender com Bia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar interesse'));
      await tester.pumpAndSettle();
      expect(find.text('Deu match!'), findsOneWidget);
    });

    testWidgets('existing match: the post offers the chat', (tester) async {
      await seedPost(db, 'p1');
      await pumpApp(
        tester,
        initialMatches: [
          Match(
            id: Match.pairId('me', 'bia'),
            userIds: Match.sortedPair('me', 'bia'),
            lastMessage: null,
            lastMessageAt: null,
          ),
        ],
      );
      expect(find.text('Enviar mensagem'), findsOneWidget);
      expect(find.text('Quero aprender com Bia'), findsNothing);
    });

    testWidgets('own posts never offer a request to yourself', (tester) async {
      await seedPost(db, 'p1', author: 'me', skills: const ['excel']);
      await pumpApp(tester);
      expect(find.textContaining('Quero aprender'), findsNothing);
    });
  });

  group('links', () {
    testWidgets('a post link opens the post; a deleted one explains', (
      tester,
    ) async {
      await seedPost(db, 'p1', text: 'post compartilhado');
      await pumpApp(tester, location: AppRoutes.post('p1'));
      expect(find.text('post compartilhado'), findsOneWidget);
      router.go(AppRoutes.post('nao-existe'));
      await tester.pumpAndSettle();
      expect(find.text('Publicação indisponível'), findsOneWidget);
    });

    test('deep links survive startup and sign-in redirects', () {
      final memory = DeepLinkMemory();
      // Cold start on a link while auth is loading: go to the splash.
      expect(
        memory.apply(AppRoutes.splash, location: '/post/p1', uri: '/post/p1'),
        AppRoutes.splash,
      );
      // Sign-in in between keeps it.
      expect(
        memory.apply(
          AppRoutes.splash,
          location: AppRoutes.signIn,
          uri: '/sign-in',
        ),
        AppRoutes.splash,
      );
      // Ready: the link wins over the default destination, once.
      expect(
        memory.apply(AppRoutes.discover, location: AppRoutes.splash, uri: '/'),
        '/post/p1',
      );
      expect(
        memory.apply(AppRoutes.discover, location: AppRoutes.splash, uri: '/'),
        AppRoutes.discover,
      );
      expect(memory.apply(null, location: '/post/p1', uri: '/post/p1'), isNull);
    });
  });

  group('composer', () {
    testWidgets('empty post is refused; a text post is published once', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.newPost);
      expect(find.byType(PostComposerScreen), findsOneWidget);
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      expect(find.text('Escreva algo ou adicione uma imagem.'), findsOneWidget);
      expect((await db.collection('posts').get()).docs, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, 'Descrição'),
        'Minha primeira dica de Excel',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Hashtags'),
        '#Excel #dica',
      );
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Excel'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Excel'));
      await tester.pump();
      // Double tap: the second one must not publish again.
      await tester.tap(find.text('Publicar'));
      await tester.tap(find.text('Publicar'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final docs = (await db.collection('posts').get()).docs;
      expect(docs, hasLength(1), reason: 'double tap publishes once');
      final post = docs.single.data();
      expect(post['authorId'], 'me');
      expect(post['tags'], ['Excel', 'dica']);
      expect(post['skillIds'], ['excel']);
      expect(find.byType(PostDetailScreen), findsOneWidget);
    });

    testWidgets('an image is processed and uploaded with the post', (
      tester,
    ) async {
      final jpeg = img.encodeJpg(img.Image(width: 64, height: 48), quality: 80);
      await pumpApp(
        tester,
        location: AppRoutes.newPost,
        picker: (limit) async => [XFile.fromData(jpeg, name: 'a.jpg')],
      );
      await tester.runAsync(() async {
        await tester.tap(find.bySemanticsLabel('Adicionar imagens'));
        // Image processing runs in a real background isolate.
        for (var i = 0; i < 50; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.bySemanticsLabel('Imagem 1 de 1').evaluate().isNotEmpty) {
            break;
          }
        }
      });
      expect(find.bySemanticsLabel('Imagem 1 de 1'), findsOneWidget);
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      final post = (await db.collection('posts').get()).docs.single;
      expect(post.data()['mediaCount'], 1);
      expect(
        (await post.reference.collection('media').doc('0').get()).exists,
        isTrue,
      );
    });
  });
}
