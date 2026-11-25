import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/features/community/community_repository.dart';
import 'package:skill_swap/features/community/models.dart';
import 'package:skill_swap/features/community/post_media.dart';
import 'package:skill_swap/features/community/post_video.dart';
import 'package:skill_swap/features/community/post_video_tools.dart';

// Fictional test data only. gps_sample.mp4: 1 s test pattern generated with
// ffmpeg, carrying a fake location, title and artist in its metadata.
Uint8List fixture() => File('test/fixtures/gps_sample.mp4').readAsBytesSync();

/// An MP4-looking byte array of [size] bytes.
Uint8List fakeMp4(int size) {
  final bytes = Uint8List(size);
  bytes.setAll(0, [0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]);
  for (var i = 8; i < size; i++) {
    bytes[i] = i % 251;
  }
  return bytes;
}

PreparedImage fakePoster() {
  final bytes = img.encodeJpg(img.Image(width: 40, height: 30), quality: 80);
  return PreparedImage(bytes: bytes, width: 40, height: 30, thumb: bytes);
}

PreparedVideo fakeVideo(int size) => PreparedVideo(
  bytes: fakeMp4(size),
  durationMs: 17458,
  width: 768,
  height: 576,
  poster: fakePoster(),
);

PostDraft videoDraft(PreparedVideo video, {List<PreparedImage>? images}) =>
    PostDraft(
      description: 'Compartilhando conhecimento! #educacao',
      type: PostType.knowledge,
      skillIds: const ['programming'],
      tags: const ['educacao'],
      images: images ?? const [],
      video: video,
    );

/// An MP4 box: 32-bit size, 4-letter type, payload.
List<int> box(String type, List<int> payload) {
  final size = payload.length + 8;
  return [
    (size >> 24) & 0xff,
    (size >> 16) & 0xff,
    (size >> 8) & 0xff,
    size & 0xff,
    ...ascii.encode(type),
    ...payload,
  ];
}

bool containsAscii(Uint8List bytes, String text) =>
    latin1.decode(bytes, allowInvalid: true).contains(text);

void main() {
  group('PostVideo.stripMetadata', () {
    test('removes location, title and artist; keeps size and media', () {
      final source = fixture();
      expect(containsAscii(source, '+40.6892-074.0445'), isTrue);
      expect(containsAscii(source, 'secret title'), isTrue);

      final out = PostVideo.stripMetadata(source)!;

      expect(out.length, source.length);
      expect(PostVideo.isMp4(out), isTrue);
      expect(containsAscii(out, '+40.6892-074.0445'), isFalse);
      expect(containsAscii(out, 'secret title'), isFalse);
      expect(containsAscii(out, 'Someone'), isFalse);
      // The source is not modified.
      expect(containsAscii(source, 'secret title'), isTrue);
    });

    test('neutralizes XMP uuid boxes', () {
      final xmp = ascii.encode('<x:xmpmeta GPSLatitude="40.68"/>');
      final source = Uint8List.fromList([
        ...fixture(),
        ...box('uuid', [...List.filled(16, 0xbe), ...xmp]),
      ]);
      final out = PostVideo.stripMetadata(source)!;
      expect(containsAscii(out, 'GPSLatitude'), isFalse);
      expect(out.length, source.length);
    });

    test('fails closed: truncated, malformed or unknown files are refused', () {
      final source = fixture();
      for (final length in [0, 7, 8, 20, 100, source.length - 3]) {
        final cut = Uint8List.sublistView(source, 0, length);
        expect(PostVideo.stripMetadata(cut), isNull, reason: 'length $length');
      }
      final garbage = Uint8List.fromList(List.generate(500, (i) => i * 7));
      expect(PostVideo.stripMetadata(garbage), isNull);
      // A box claiming to be larger than the file.
      final huge = Uint8List.fromList([0x7f, 0, 0, 0, ...ascii.encode('moov')]);
      expect(PostVideo.stripMetadata(huge), isNull);
      // No moov at all.
      expect(
        PostVideo.stripMetadata(Uint8List.fromList(box('ftyp', [0]))),
        isNull,
      );
    });

    test(
      'refuses timed metadata tracks (GPS streams) and leftover markers',
      () {
        List<int> trak(String handler) => box('trak', [
          ...box('mdia', [
            ...box('hdlr', [0, 0, 0, 0, 0, 0, 0, 0, ...ascii.encode(handler)]),
          ]),
        ]);
        final ftyp = box('ftyp', ascii.encode('isom'));
        final ok = Uint8List.fromList([...ftyp, ...box('moov', trak('vide'))]);
        expect(PostVideo.stripMetadata(ok), isNotNull);
        final gps = Uint8List.fromList([
          ...ftyp,
          ...box('moov', [...trak('vide'), ...trak('meta')]),
        ]);
        expect(PostVideo.stripMetadata(gps), isNull);
        // Location left inside the media data cannot be cleaned: refused.
        final inMdat = Uint8List.fromList([
          ...ok,
          ...box('mdat', ascii.encode('+40.6892-074.0445/ISO6709')),
        ]);
        expect(PostVideo.stripMetadata(inMdat), isNull);
      },
    );

    test('deeply nested boxes cannot overflow the stack', () {
      List<int> nested = box('moov', []);
      for (var i = 0; i < 2000; i++) {
        nested = box('moov', nested);
      }
      final file = Uint8List.fromList([
        ...box('ftyp', [0]),
        ...nested,
      ]);
      expect(() => PostVideo.stripMetadata(file), returnsNormally);
    });
  });

  group('PostVideo limits', () {
    test('chunk count and split match the rules (800 KiB chunks)', () {
      expect(PostVideo.chunkCount(0), 0);
      expect(PostVideo.chunkCount(1), 1);
      expect(PostVideo.chunkCount(PostVideo.chunkBytes), 1);
      expect(PostVideo.chunkCount(PostVideo.chunkBytes + 1), 2);
      expect(PostVideo.chunkCount(PostVideo.maxBytes), 3);

      final bytes = fakeMp4(PostVideo.chunkBytes * 2 + 10);
      final parts = PostVideo.split(bytes);
      expect(parts.map((p) => p.length), [
        PostVideo.chunkBytes,
        PostVideo.chunkBytes,
        10,
      ]);
      expect(parts.expand((p) => p).toList(), bytes);
    });

    test('isMp4 checks the ftyp signature', () {
      expect(PostVideo.isMp4(fixture()), isTrue);
      expect(PostVideo.isMp4(fakeMp4(12)), isTrue);
      expect(
        PostVideo.isMp4(Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0])),
        isFalse,
      );
      expect(PostVideo.isMp4(Uint8List(100)), isFalse);
    });

    test('stored descriptions are validated', () {
      final valid = {
        'chunks': 2,
        'bytes': PostVideo.chunkBytes + 5,
        'durationMs': 17458,
        'width': 768,
        'height': 576,
      };
      expect(PostVideoInfo.tryParse(valid), isNotNull);
      expect(PostVideoInfo.tryParse(null), isNull);
      expect(PostVideoInfo.tryParse({...valid, 'chunks': 1}), isNull);
      expect(PostVideoInfo.tryParse({...valid, 'durationMs': 60001}), isNull);
      expect(PostVideoInfo.tryParse({...valid, 'width': '768'}), isNull);
      expect(PostVideoInfo.tryParse({...valid, 'height': 0}), isNull);
    });

    test('durations are shown as m:ss', () {
      expect(
        PostVideoTools.formatDuration(const Duration(seconds: 17)),
        '0:17',
      );
      expect(
        PostVideoTools.formatDuration(const Duration(seconds: 60)),
        '1:00',
      );
      expect(PostVideoTools.fileName('ana_x/../y'), 'ana_x____y');
    });
  });

  group('CommunityRepository video posts', () {
    late FakeFirebaseFirestore db;
    late CommunityRepository posts;

    setUp(() {
      db = FakeFirebaseFirestore();
      posts = CommunityRepository(db);
    });

    test('publishes the poster, the description and every chunk', () async {
      final video = fakeVideo(PostVideo.chunkBytes + 1000);
      final id = posts.newPostId('dani');
      await posts.createPost(
        postId: id,
        authorId: 'dani',
        draft: videoDraft(video),
      );
      final data = (await db.doc('posts/$id').get()).data()!;
      expect(data['type'], 'knowledge');
      expect(data['mediaCount'], 1);
      expect(data['thumb'], isA<Blob>());
      expect(data['video'], {
        'chunks': 2,
        'bytes': PostVideo.chunkBytes + 1000,
        'durationMs': 17458,
        'width': 768,
        'height': 576,
      });
      expect((await db.doc('posts/$id/media/0').get()).exists, isTrue);
      expect((await db.doc('posts/$id/video/0').get()).exists, isTrue);
      expect((await db.doc('posts/$id/video/1').get()).exists, isTrue);
      final stamp = (await db.doc('rateLimits/dani').get()).data()!;
      expect(stamp['lastVideoAt'], isA<Timestamp>());
      expect(await posts.videoCooldownLeft('dani'), 60);
      expect(
        await posts.videoCooldownLeft(
          'dani',
          now: DateTime.now().add(const Duration(minutes: 61)),
        ),
        0,
      );

      final post = CommunityPost.fromDoc(await db.doc('posts/$id').get());
      expect(post.video, video.info);
      final stored = await posts.getVideo(id, post.video!);
      expect(stored, video.bytes);
    });

    test(
      'refuses a video together with images, too large or not MP4',
      () async {
        final ok = fakeVideo(1000);
        final bad = [
          videoDraft(ok, images: [fakePoster()]),
          videoDraft(fakeVideo(PostVideo.maxBytes + 1)),
          videoDraft(
            PreparedVideo(
              bytes: Uint8List.fromList(List.filled(100, 1)),
              durationMs: 1000,
              width: 10,
              height: 10,
              poster: fakePoster(),
            ),
          ),
          videoDraft(
            PreparedVideo(
              bytes: fakeMp4(1000),
              durationMs: 61000,
              width: 10,
              height: 10,
              poster: fakePoster(),
            ),
          ),
        ];
        for (final draft in bad) {
          await expectLater(
            posts.createPost(
              postId: posts.newPostId('dani'),
              authorId: 'dani',
              draft: draft,
            ),
            throwsA(isA<InvalidPostFailure>()),
          );
        }
        expect((await db.collection('posts').get()).docs, isEmpty);
      },
    );

    test('a missing or altered chunk is detected before playing', () async {
      final video = fakeVideo(PostVideo.chunkBytes + 1000);
      final id = posts.newPostId('dani');
      await posts.createPost(
        postId: id,
        authorId: 'dani',
        draft: videoDraft(video),
      );
      await db.doc('posts/$id/video/1').set({'data': Blob(fakeMp4(10))});
      await expectLater(
        posts.getVideo(id, video.info),
        throwsA(isA<InvalidVideoFailure>()),
      );
      await db.doc('posts/$id/video/1').delete();
      await expectLater(
        posts.getVideo(id, video.info),
        throwsA(isA<InvalidVideoFailure>()),
      );
    });

    test('deleting removes the poster and every chunk', () async {
      final id = posts.newPostId('dani');
      await posts.createPost(
        postId: id,
        authorId: 'dani',
        draft: videoDraft(fakeVideo(PostVideo.chunkBytes * 2 + 1)),
      );
      final post = CommunityPost.fromDoc(await db.doc('posts/$id').get());
      await posts.deletePost(post);
      expect((await db.doc('posts/$id').get()).exists, isFalse);
      expect((await db.doc('posts/$id/media/0').get()).exists, isFalse);
      for (var i = 0; i < 3; i++) {
        expect((await db.doc('posts/$id/video/$i').get()).exists, isFalse);
      }
    });

    test(
      'a post whose video cannot be parsed still deletes its chunks',
      () async {
        final id = posts.newPostId('dani');
        await posts.createPost(
          postId: id,
          authorId: 'dani',
          draft: videoDraft(fakeVideo(1000)),
        );
        await db.doc('posts/$id').update({'video.chunks': 'x'});
        final post = CommunityPost.fromDoc(await db.doc('posts/$id').get());
        expect(post.video, isNull);
        await posts.deletePost(post);
        expect((await db.doc('posts/$id/video/0').get()).exists, isFalse);
      },
    );

    test('a malformed stored video is ignored (image post shown)', () async {
      await db.doc('posts/x').set({
        'authorId': 'dani',
        'description': 'oi',
        'type': 'knowledge',
        'mediaCount': 1,
        'aspectRatios': [1.33],
        'video': {
          'chunks': 9,
          'bytes': 1,
          'durationMs': 1,
          'width': 1,
          'height': 1,
        },
        'createdAt': Timestamp.now(),
      });
      final post = CommunityPost.fromDoc(await db.doc('posts/x').get());
      expect(post.type, PostType.knowledge);
      expect(post.video, isNull);
    });
  });
}
