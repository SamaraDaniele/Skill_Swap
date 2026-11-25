import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/features/community/community_repository.dart';
import 'package:skill_swap/features/community/models.dart';
import 'package:skill_swap/features/community/post_links.dart';
import 'package:skill_swap/features/community/post_media.dart';
import 'package:skill_swap/features/community/social_repository.dart';
import 'package:skill_swap/features/matches/matches.dart';
import 'package:skill_swap/features/safety/safety.dart';

// Fictional test data only.
PostDraft draft({
  String text = 'Finalizei meu app de tarefas! #Flutter',
  List<PreparedImage> images = const [],
}) => PostDraft(
  description: text,
  type: PostType.project,
  skillIds: const ['programming'],
  tags: const ['Flutter', 'App'],
  images: images,
);

PreparedImage fakeImage() {
  final bytes = img.encodeJpg(img.Image(width: 40, height: 30), quality: 80);
  return PreparedImage(bytes: bytes, width: 40, height: 30, thumb: bytes);
}

FirebaseException fsError(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  late FakeFirebaseFirestore db;
  late CommunityRepository posts;
  late SocialRepository social;

  setUp(() {
    db = FakeFirebaseFirestore();
    posts = CommunityRepository(db);
    social = SocialRepository(db);
  });

  group('CommunityRepository', () {
    test('creates the post, its images and the anti-spam stamp', () async {
      final id = posts.newPostId('ana');
      await posts.createPost(
        postId: id,
        authorId: 'ana',
        draft: draft(images: [fakeImage(), fakeImage()]),
      );
      final doc = await db.doc('posts/$id').get();
      expect(doc.data()!['authorId'], 'ana');
      expect(doc.data()!['visibility'], 'public');
      expect(doc.data()!['mediaCount'], 2);
      expect(doc.data()!['thumb'], isA<Blob>());
      expect(
        doc.data()!['keywords'],
        containsAll(['flutter', 'app', 'programming', 'finalizei']),
      );
      expect((await db.doc('posts/$id/media/0').get()).exists, isTrue);
      expect((await db.doc('posts/$id/media/1').get()).exists, isTrue);
      expect((await db.doc('rateLimits/ana').get()).exists, isTrue);
    });

    test('refuses an empty post (no text, no images)', () async {
      await expectLater(
        posts.createPost(
          postId: posts.newPostId('ana'),
          authorId: 'ana',
          draft: draft(text: '   '),
        ),
        throwsA(isA<InvalidPostFailure>()),
      );
      expect((await db.collection('posts').get()).docs, isEmpty);
    });

    test('a retry with the same id never duplicates the post', () async {
      final id = posts.newPostId('ana');
      await posts.createPost(postId: id, authorId: 'ana', draft: draft());
      await posts.createPost(postId: id, authorId: 'ana', draft: draft());
      expect((await db.collection('posts').get()).docs, hasLength(1));
    });

    test('upload failure is reported, nothing is shown as published', () async {
      final id = posts.newPostId('ana');
      whenCalling(Invocation.method(#set, null))
          .on(db.doc('posts/$id'))
          .thenThrow(fsError('unavailable'));
      await expectLater(
        posts.createPost(postId: id, authorId: 'ana', draft: draft()),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('a slow or dropped connection is a network failure', () async {
      await db.doc('posts/p1').set({'authorId': 'ana'});
      whenCalling(Invocation.method(#update, null))
          .on(db.doc('posts/p1'))
          .thenThrow(fsError('deadline-exceeded'));
      await expectLater(
        posts.updatePost('p1', draft()),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('edits text/type/tags and deletes the post with its images', () async {
      final id = posts.newPostId('ana');
      await posts.createPost(
        postId: id,
        authorId: 'ana',
        draft: draft(images: [fakeImage()]),
      );
      await posts.updatePost(
        id,
        const PostDraft(
          description: 'Texto novo',
          type: PostType.tip,
          skillIds: [],
          tags: ['Dica'],
        ),
      );
      final edited = (await posts.getPost(id))!;
      expect(edited.description, 'Texto novo');
      expect(edited.type, PostType.tip);
      expect(edited.tags, ['Dica']);
      expect(edited.mediaCount, 1, reason: 'images are not editable');

      await posts.deletePost(edited);
      expect(await posts.getPost(id), isNull);
      expect((await db.doc('posts/$id/media/0').get()).exists, isFalse);
    });

    test('paginates with a cursor, newest first', () async {
      for (var i = 0; i < 13; i++) {
        await db.collection('posts').doc('p$i').set({
          'authorId': 'ana',
          'description': 'post $i',
          'type': 'project',
          'skillIds': <String>[],
          'tags': <String>[],
          'keywords': <String>[],
          'mediaCount': 0,
          'aspectRatios': <double>[],
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(1000 * i),
        });
      }
      final first = await posts.fetchPage(PostQuery.forYou);
      expect(first.posts, hasLength(10));
      expect(first.posts.first.id, 'p12');
      expect(first.hasMore, isTrue);
      final second = await posts.fetchPage(
        PostQuery.forYou,
        cursor: first.cursor,
      );
      expect(second.posts.map((p) => p.id), ['p2', 'p1', 'p0']);
      expect(second.hasMore, isFalse);
      expect(await posts.countByAuthor('ana'), 13);
    });

    test(
      'filters: projects, author, skill, keyword; empty follow list',
      () async {
        Future<void> add(String id, String author, String type, String skill) =>
            db.collection('posts').doc(id).set({
              'authorId': author,
              'description': '',
              'type': type,
              'skillIds': [skill],
              'tags': <String>[],
              'keywords': [skill, 'grafico'],
              'mediaCount': 0,
              'aspectRatios': <double>[],
              'createdAt': Timestamp.now(),
            });
        await add('a', 'ana', 'project', 'design');
        await add('b', 'bia', 'tip', 'excel');
        Future<List<String>> ids(PostQuery q) async =>
            (await posts.fetchPage(q)).posts.map((p) => p.id).toList();
        expect(await ids(PostQuery.projects), ['a']);
        expect(await ids(PostQuery.author('bia')), ['b']);
        expect(await ids(PostQuery.skill('excel')), ['b']);
        expect(await ids(PostQuery.skills(['design', 'math'])), ['a']);
        expect(await ids(PostQuery.following(['bia'])), ['b']);
        expect(await ids(PostQuery.following(const [])), isEmpty);
        expect(
          await ids(PostQuery.keyword(CommunityText.searchKeyword('Gráfico')!)),
          unorderedEquals(['a', 'b']),
        );
      },
    );

    test('cooldown left is read from the anti-spam stamp', () async {
      final now = DateTime(2026, 11, 20, 12);
      await db.doc('rateLimits/ana').set({
        'lastPostAt': Timestamp.fromDate(
          now.subtract(const Duration(seconds: 10)),
        ),
      });
      expect(await posts.postCooldownLeft('ana', now: now), 21);
      expect(await posts.postCooldownLeft('bia', now: now), 0);
    });
  });

  group('SocialRepository', () {
    setUp(() async {
      await db.doc('posts/p1').set({
        'authorId': 'bia',
        'description': 'oi',
        'type': 'tip',
        'createdAt': Timestamp.now(),
      });
    });

    test('like / unlike with count; one like per member', () async {
      await social.like(postId: 'p1', uid: 'ana', authorId: 'bia');
      await social.like(postId: 'p1', uid: 'ana', authorId: 'bia');
      expect(await social.likeCount('p1'), 1, reason: 'doc id is the uid');
      expect(await social.isLiked('p1', 'ana'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        (await db.doc('users/bia/notifications/like_p1_ana').get()).exists,
        isTrue,
      );

      await social.unlike(postId: 'p1', uid: 'ana', authorId: 'bia');
      await Future<void>.delayed(Duration.zero);
      expect(await social.likeCount('p1'), 0);
      expect(
        (await db.doc('users/bia/notifications/like_p1_ana').get()).exists,
        isFalse,
        reason: 'the notification is withdrawn',
      );
    });

    test('no notification for liking your own post', () async {
      await social.like(postId: 'p1', uid: 'bia', authorId: 'bia');
      await Future<void>.delayed(Duration.zero);
      expect(
        (await db.collection('users/bia/notifications').get()).docs,
        isEmpty,
      );
    });

    test('comments, one reply level, delete takes the replies', () async {
      final top = await social.addComment(
        postId: 'p1',
        postAuthorId: 'bia',
        uid: 'ana',
        text: '  Ficou incrível!  ',
      );
      expect(top.text, 'Ficou incrível!');
      final reply = await social.addComment(
        postId: 'p1',
        postAuthorId: 'bia',
        uid: 'bia',
        text: 'Obrigada!',
        parent: top,
      );
      // A reply to a reply still attaches to the top-level comment.
      final nested = await social.addComment(
        postId: 'p1',
        postAuthorId: 'bia',
        uid: 'ana',
        text: 'De nada',
        parent: reply,
      );
      expect(reply.parentId, top.id);
      expect(nested.parentId, top.id);
      expect(await social.commentCount('p1'), 3);
      final topLevel = await social.fetchComments('p1');
      expect(topLevel.comments.map((c) => c.id), [top.id]);
      final replies = await social.fetchComments('p1', parentId: top.id);
      expect(replies.comments, hasLength(2));
      await Future<void>.delayed(Duration.zero);
      expect(
        (await db.doc('users/bia/notifications/comment_${top.id}').get())
            .exists,
        isTrue,
      );
      expect(
        (await db.doc('users/ana/notifications/reply_${reply.id}').get())
            .exists,
        isTrue,
      );

      await social.deleteComment(top);
      expect(await social.commentCount('p1'), 0);
    });

    test('empty comments are refused', () {
      expect(
        social.addComment(
          postId: 'p1',
          postAuthorId: 'bia',
          uid: 'ana',
          text: '   ',
        ),
        throwsA(isA<InvalidPostFailure>()),
      );
    });

    test('saved posts: private list, no duplicates, newest first', () async {
      await db.doc('posts/p2').set({'authorId': 'bia'});
      await social.setSaved(uid: 'ana', postId: 'p1', saved: true);
      await social.setSaved(uid: 'ana', postId: 'p1', saved: true);
      await social.setSaved(uid: 'ana', postId: 'p2', saved: true);
      final page = await social.fetchSaved('ana');
      expect(page.ids.toSet(), {'p1', 'p2'});
      expect(await social.watchSaved('ana', 'p1').first, isTrue);
      await social.setSaved(uid: 'ana', postId: 'p1', saved: false);
      expect(await social.watchSaved('ana', 'p1').first, isFalse);
    });

    test('follow / unfollow, counts and lists; never yourself', () async {
      await social.follow('ana', 'bia');
      await social.follow('caio', 'bia');
      expect(await social.followerCount('bia'), 2);
      expect(await social.followingCount('ana'), 1);
      expect(await social.watchFollowing('ana', 'bia').first, isTrue);
      expect(await social.watchFollowingIds('ana').first, ['bia']);
      final followers = await social.fetchFollows('bia', followers: true);
      expect(followers.ids.toSet(), {'ana', 'caio'});
      await Future<void>.delayed(Duration.zero);
      expect(
        (await db.doc('users/bia/notifications/follow_ana').get()).exists,
        isTrue,
      );

      await social.unfollow('ana', 'bia');
      expect(await social.followerCount('bia'), 1);
      expect(social.follow('ana', 'ana'), throwsA(isA<PermissionFailure>()));
    });

    test('notifications: unread count and mark as read', () async {
      await social.follow('ana', 'bia');
      await social.like(postId: 'p1', uid: 'ana', authorId: 'bia');
      await Future<void>.delayed(Duration.zero);
      expect(await social.watchUnreadCount('bia').first, 2);
      final items = await social.watchNotifications('bia').first;
      expect(items.map((n) => n.type).toSet(), {
        NotificationType.follow,
        NotificationType.like,
      });
      await social.markRead('bia', items.map((n) => n.id));
      expect(await social.watchUnreadCount('bia').first, 0);
    });
  });

  group('Safety in the community', () {
    test('blocking removes the follows in both directions', () async {
      await db.doc('follows/ana_bia').set({'followerId': 'ana'});
      await db.doc('follows/bia_ana').set({'followerId': 'bia'});
      await SafetyRepository(db).block(me: 'ana', other: 'bia');
      expect((await db.doc('blocks/ana_bia').get()).exists, isTrue);
      expect((await db.doc('follows/ana_bia').get()).exists, isFalse);
      expect((await db.doc('follows/bia_ana').get()).exists, isFalse);
    });

    test('report of a post or comment has the content shape', () async {
      final safety = SafetyRepository(db);
      await safety.reportContent(
        me: 'ana',
        authorId: 'bia',
        postId: 'p1',
        reason: ReportReason.scam,
        details: 'link suspeito',
      );
      await safety.reportContent(
        me: 'ana',
        authorId: 'bia',
        postId: 'p1',
        commentId: 'c1',
        reason: ReportReason.offensive,
        details: '',
      );
      final reports = (await db.collection('reports').get()).docs
          .map((d) => d.data())
          .toList();
      expect(reports.map((r) => r['targetType']).toSet(), {'post', 'comment'});
      expect(reports.every((r) => !r.containsKey('matchId')), isTrue);
      expect(
        (await db.collection('blocks').get()).docs,
        isEmpty,
        reason: 'reporting content does not block',
      );
    });

    test('match id and pair ids stay compatible', () {
      expect(Match.pairId('bia', 'ana'), 'ana_bia');
    });
  });

  group('CommunityText', () {
    test('parses hashtags: strips #, drops invalid and duplicates', () {
      expect(CommunityText.parseTags('#Design, #UIUX #design ui-ux #Gráfico'), [
        'Design',
        'UIUX',
        'Gráfico',
      ]);
      expect(
        CommunityText.parseTags(List.generate(15, (i) => '#t$i').join(' ')),
        hasLength(CommunityLimits.maxTags),
      );
    });

    test('keywords are normalized, unique and capped', () {
      final words = CommunityText.keywords(
        description: 'Identidade Visual e Identidade gráfica',
        tags: const ['Branding'],
        skillIds: const ['design'],
      );
      expect(
        words,
        containsAll(['branding', 'design', 'identidade', 'grafica']),
      );
      expect(words.where((w) => w == 'identidade'), hasLength(1));
      expect(words, isNot(contains('e')), reason: 'too short');
      expect(CommunityText.searchKeyword('#Gráfico!'), 'grafico');
      expect(CommunityText.searchKeyword('a'), isNull);
    });

    test('post links round-trip', () {
      final link = PostLinks.forPost('abc123');
      expect(link, 'skillswap://app/post/abc123');
      expect(PostLinks.findPostId('Olha: $link'), 'abc123');
      expect(PostLinks.findPostId('https://exemplo.com/post/x'), isNull);
    });
  });

  group('CommunityPost.fromDoc', () {
    test(
      'is tolerant: drops unknown skills, bad tags and bad thumbs',
      () async {
        await db.doc('posts/x').set({
          'authorId': 'ana',
          'description': 'oi',
          'type': 'hack',
          'skillIds': ['design', 'not-a-skill', 3],
          'tags': ['ok', 'not ok', 5],
          'mediaCount': 99,
          'aspectRatios': [10, 'x'],
          'thumb': Blob(Uint8List.fromList([1, 2, 3])),
        });
        final post = CommunityPost.fromDoc(await db.doc('posts/x').get());
        expect(post.type, PostType.work);
        expect(post.skillIds, ['design']);
        expect(post.tags, ['ok']);
        expect(post.mediaCount, CommunityLimits.maxImages);
        expect(post.aspectRatios.first, PostImage.maxAspect);
        expect(post.aspectRatios, hasLength(CommunityLimits.maxImages));
        expect(post.thumb, isNull);
      },
    );
  });

  group('PostImage', () {
    test(
      'prepares a large image within the limits, without metadata',
      () async {
        final source = img.encodeJpg(
          img.Image(width: 3000, height: 2000),
          quality: 95,
        );
        final prepared = await PostImage.prepare(source);
        expect(prepared.width, PostImage.maxSide);
        expect(prepared.height, 960);
        expect(prepared.bytes.length, lessThanOrEqualTo(PostImage.maxBytes));
        expect(PostImage.isAcceptable(prepared.bytes), isTrue);
        expect(PostImage.isAcceptableThumb(prepared.thumb), isTrue);
        expect(
          prepared.thumb.length,
          lessThanOrEqualTo(PostImage.thumbMaxBytes),
        );
      },
    );

    test('rejects files that are not images', () {
      expect(
        PostImage.prepare(Uint8List.fromList(List.filled(100, 7))),
        throwsA(isA<InvalidImageFailure>()),
      );
      expect(
        PostImage.prepare(Uint8List(0)),
        throwsA(isA<InvalidImageFailure>()),
      );
    });
  });
}
