import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/core/firebase_providers.dart';
import 'package:skill_swap/core/l10n/l10n.dart';
import 'package:skill_swap/core/router/app_router.dart';
import 'package:skill_swap/core/router/app_routes.dart';
import 'package:skill_swap/core/theme/app_theme.dart';
import 'package:skill_swap/features/auth/auth_repository.dart';
import 'package:skill_swap/features/community/community_providers.dart';
import 'package:skill_swap/features/community/community_repository.dart';
import 'package:skill_swap/features/community/models.dart';
import 'package:skill_swap/features/community/post_media.dart';
import 'package:skill_swap/features/community/post_video.dart';
import 'package:skill_swap/features/community/post_video_tools.dart';
import 'package:skill_swap/features/community/presentation/post_video_player.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

// Fictional test data only.
const me = UserProfile(
  id: 'me',
  name: 'Ana Teste',
  bio: 'Ensino Excel.',
  teach: ['excel'],
  learn: ['design'],
);

const videoInfo = PostVideoInfo(
  chunks: 1,
  bytes: 1000,
  durationMs: 17458,
  width: 768,
  height: 576,
);

/// Records what the app asks the native player to do.
class FakeVideoPlatform extends VideoPlayerPlatform {
  final calls = <String>[];

  /// Players currently playing.
  final playing = <int>{};
  final _events = <int, StreamController<VideoEvent>>{};
  int _next = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _next++;
    _events[id] = StreamController<VideoEvent>();
    calls.add('create ${dataSource.uri}');
    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      create(options.dataSource);

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final events = _events[playerId]!;
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(milliseconds: 17458),
          size: const Size(768, 576),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
    playing.add(playerId);
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause');
    playing.remove(playerId);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      calls.add('volume $volume');

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      calls.add('seek ${position.inSeconds}');

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => const ColoredBox(
    key: Key('fake-video-surface'),
    color: Color(0xFF123456),
  );

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      buildView(options.playerId);
}

Uint8List jpeg() =>
    img.encodeJpg(img.Image(width: 64, height: 48), quality: 80);

PreparedImage poster() {
  final bytes = jpeg();
  return PreparedImage(bytes: bytes, width: 64, height: 48, thumb: bytes);
}

PreparedVideo preparedVideo() {
  final bytes = Uint8List(1000)
    ..setAll(0, [0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
  return PreparedVideo(
    bytes: bytes,
    durationMs: 17458,
    width: 768,
    height: 576,
    poster: poster(),
  );
}

Future<void> seedVideoPost(
  FakeFirebaseFirestore db, {
  String id = 'dani_video',
}) async {
  await db.doc('users/dani').set({
    'name': 'Daniel Moreira',
    'bio': '',
    'teach': ['programming'],
    'learn': ['excel'],
    'updatedAt': Timestamp.now(),
  });
  await db.doc('posts/$id').set({
    'authorId': 'dani',
    'description': 'Compartilhando um pouco de conhecimento!',
    'type': 'knowledge',
    'skillIds': ['programming'],
    'tags': ['conhecimento'],
    'keywords': ['conhecimento'],
    'visibility': 'public',
    'mediaCount': 1,
    'aspectRatios': [1.33],
    'thumb': Blob(jpeg()),
    'video': videoInfo.toMap(),
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 1)),
    ),
    'updatedAt': Timestamp.now(),
  });
  await db.doc('posts/$id/media/0').set({
    'data': Blob(jpeg()),
    'width': 64,
    'height': 48,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  late FakeVideoPlatform platform;
  late GoRouter router;
  late List<VideoKey> downloads;

  setUp(() async {
    db = FakeFirebaseFirestore();
    platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    downloads = [];
    await ProfileRepository(db).save(me);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String location = AppRoutes.community,
    PostVideoPicker? videoPicker,
    Future<String> Function(VideoKey key)? videoFile,
    Size size = const Size(412, 915),
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
          matchesProvider.overrideWith((ref) => Stream.value(const [])),
          postVideoFileProvider.overrideWith((ref, key) async {
            downloads.add(key);
            if (videoFile != null) return videoFile(key);
            return '/cache/post_videos/${key.postId}.mp4';
          }),
          if (videoPicker != null)
            postVideoPickerProvider.overrideWithValue(videoPicker),
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
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go(location);
    await tester.pumpAndSettle();
  }

  /// Lets the fake player initialize (no pumpAndSettle: the playing
  /// controller polls its position).
  Future<void> settlePlayer(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('video in the feed', () {
    testWidgets('shows the poster and duration; nothing downloads or plays '
        'until the member taps play', (tester) async {
      await seedVideoPost(db);
      await pumpApp(tester);

      expect(find.byType(PostVideoPlayer), findsOneWidget);
      expect(find.bySemanticsLabel('Vídeo de 0:17'), findsOneWidget);
      expect(find.text('0:17'), findsOneWidget);
      expect(find.text('Conhecimento'), findsOneWidget);
      expect(find.byTooltip('Reproduzir vídeo'), findsOneWidget);
      expect(downloads, isEmpty);
      expect(platform.calls, isEmpty, reason: 'no autoplay');

      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await settlePlayer(tester);

      expect(downloads.single.postId, 'dani_video');
      expect(downloads.single.video, videoInfo);
      expect(platform.calls.first, startsWith('create file:'));
      expect(platform.calls.first, endsWith('/post_videos/dani_video.mp4'));
      expect(platform.calls.last, 'play');
      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
      expect(find.byTooltip('Pausar vídeo'), findsOneWidget);

      await tester.tap(find.byTooltip('Pausar vídeo'));
      await settlePlayer(tester);
      expect(platform.calls.last, 'pause');

      await tester.tap(find.byTooltip('Desativar som'));
      await settlePlayer(tester);
      expect(platform.calls.last, 'volume 0.0');
      expect(find.byTooltip('Ativar som'), findsOneWidget);
    });

    testWidgets('full screen keeps playing the same video; leaving the tab '
        'pauses it', (tester) async {
      await seedVideoPost(db);
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await settlePlayer(tester);

      // Startup applies volume and the paused state before playing.
      final started = platform.calls.length;
      List<String> since() => platform.calls.sublist(started);

      await tester.tap(find.byTooltip('Tela cheia'));
      await settlePlayer(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PostVideoFullscreen), findsOneWidget);
      expect(since(), isNot(contains('pause')));
      expect(platform.calls.where((c) => c.startsWith('create')), hasLength(1));

      await tester.tap(find.byTooltip('Sair da tela cheia'));
      await settlePlayer(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PostVideoFullscreen), findsNothing);
      expect(since(), isNot(contains('pause')));
      expect(since(), isNot(contains('dispose')));

      await tester.tap(find.text('Perfil').last);
      await settlePlayer(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(since(), contains('pause'));
    });

    testWidgets('a failed download shows a retry button', (tester) async {
      await seedVideoPost(db);
      tester.view
        ..physicalSize = const Size(412, 915)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            authStateProvider.overrideWith((ref) => Stream.value('me')),
            currentProfileProvider.overrideWith((ref) => Stream.value(me)),
            // Same caching as the real provider: a retry must not get
            // the cached failure.
            postVideoFileProvider.overrideWith((ref, key) async {
              cacheFor(ref, const Duration(minutes: 5));
              attempts++;
              throw const InvalidVideoFailure();
            }),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final post = ref.watch(postProvider('dani_video')).value;
              return MaterialApp(
                theme: AppTheme.dark(),
                locale: const Locale('pt'),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: post == null
                      ? const SizedBox()
                      : PostVideoPlayer(post: post),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar o vídeo.'), findsOneWidget);
      expect(find.byTooltip('Tentar novamente'), findsOneWidget);
      expect(platform.calls, isEmpty);
      await tester.tap(find.byTooltip('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
    });
  });

  group('player lifecycle', () {
    testWidgets('a download that ends after leaving the tab does not play', (
      tester,
    ) async {
      await seedVideoPost(db);
      final download = Completer<String>();
      await pumpApp(tester, videoFile: (_) => download.future);
      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await tester.pump();
      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      download.complete('/cache/post_videos/dani_video.mp4');
      await settlePlayer(tester);
      expect(platform.playing, isEmpty, reason: 'no sound off screen');
    });

    testWidgets('starting a second video pauses the first', (tester) async {
      await seedVideoPost(db);
      await seedVideoPost(db, id: 'dani_video2');
      // Tall screen: both cards visible at once.
      await pumpApp(tester, size: const Size(412, 2400));
      await tester.tap(find.byTooltip('Reproduzir vídeo').first);
      await settlePlayer(tester);
      expect(platform.playing, hasLength(1));
      final first = platform.playing.single;
      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await settlePlayer(tester);
      expect(platform.playing, hasLength(1), reason: '${platform.calls}');
      expect(
        platform.playing.single,
        isNot(first),
        reason: '${platform.calls}',
      );
    });

    testWidgets('leaving the screen while full screen is open releases the '
        'player without errors', (tester) async {
      await seedVideoPost(db);
      await pumpApp(tester, location: AppRoutes.post('dani_video'));
      await tester.tap(find.byTooltip('Reproduzir vídeo'));
      await settlePlayer(tester);
      await tester.tap(find.byTooltip('Tela cheia'));
      await settlePlayer(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PostVideoFullscreen), findsOneWidget);

      // E.g. a sign-out redirect: the card and the full-screen route go.
      router.go(AppRoutes.community);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(PostVideoFullscreen), findsNothing);
      // The old card is gone; only the feed's (idle) card remains.
      expect(find.byType(PostVideoPlayer, skipOffstage: false), findsOneWidget);
      expect(find.byTooltip('Reproduzir vídeo'), findsOneWidget);
    });
  });

  group('composer with a video', () {
    testWidgets('a picked video replaces the images and is published with '
        'its chunks', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.newPost,
        videoPicker: () async => preparedVideo(),
      );
      expect(find.bySemanticsLabel('Adicionar vídeo'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Adicionar vídeo'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Vídeo de 0:17'), findsOneWidget);
      expect(find.bySemanticsLabel('Adicionar imagens'), findsNothing);
      expect(find.bySemanticsLabel('Adicionar vídeo'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Descrição'),
        'Compartilhando conhecimento',
      );
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Conhecimento'),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Conhecimento'));
      await tester.pump();
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();

      final post = (await db.collection('posts').get()).docs.single;
      expect(post.data()['type'], 'knowledge');
      expect(post.data()['mediaCount'], 1);
      expect(post.data()['video'], preparedVideo().info.toMap());
      expect(
        (await post.reference.collection('video').doc('0').get()).exists,
        isTrue,
      );
    });

    testWidgets('an unusable video is explained, nothing is attached', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: AppRoutes.newPost,
        videoPicker: () async => throw const InvalidVideoFailure(),
      );
      await tester.tap(find.bySemanticsLabel('Adicionar vídeo'));
      await tester.pumpAndSettle();
      expect(
        find.text('Use um vídeo MP4 de até 60 segundos e 2,3 MB.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Adicionar vídeo'), findsOneWidget);
    });
  });

  group('postVideoFileProvider', () {
    test(
      'downloads once into the cache directory and reuses the file',
      () async {
        final dir = await Directory.systemTemp.createTemp('post_video_test');
        addTearDown(() => dir.delete(recursive: true));
        final video = preparedVideo();
        final repo = CommunityRepository(db);
        await repo.createPost(
          postId: 'dani_abcdefghijklmnopqrst',
          authorId: 'dani',
          draft: PostDraft(
            description: 'oi',
            type: PostType.knowledge,
            skillIds: const [],
            tags: const [],
            video: video,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            videoCacheDirProvider.overrideWithValue(() async => dir),
          ],
        );
        addTearDown(container.dispose);
        final key = (postId: 'dani_abcdefghijklmnopqrst', video: video.info);

        final path = await container.read(postVideoFileProvider(key).future);
        expect(File(path).readAsBytesSync(), video.bytes);
        expect(path, startsWith(dir.path));

        // Second time: served from the file even if the server is unreachable.
        await db.doc('posts/dani_abcdefghijklmnopqrst/video/0').delete();
        container.invalidate(postVideoFileProvider(key));
        final again = await container.read(postVideoFileProvider(key).future);
        expect(again, path);
      },
    );
  });
}
