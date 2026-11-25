import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import 'models.dart';
import 'post_media.dart';
import 'post_video.dart';

enum PostQueryKind {
  forYou,
  following,
  skills,
  projects,
  author,
  keyword,
  skill,
}

class PostQuery {
  const PostQuery._(this.kind, [this.values = const []]);

  static const PostQuery forYou = PostQuery._(PostQueryKind.forYou);

  static const PostQuery projects = PostQuery._(PostQueryKind.projects);

  factory PostQuery.following(List<String> authorIds) =>
      PostQuery._(PostQueryKind.following, authorIds);

  factory PostQuery.skills(List<String> skillIds) =>
      PostQuery._(PostQueryKind.skills, skillIds);

  factory PostQuery.author(String uid) =>
      PostQuery._(PostQueryKind.author, [uid]);

  factory PostQuery.keyword(String keyword) =>
      PostQuery._(PostQueryKind.keyword, [keyword]);

  factory PostQuery.skill(String skillId) =>
      PostQuery._(PostQueryKind.skill, [skillId]);

  final PostQueryKind kind;
  final List<String> values;

  bool get isEmpty => switch (kind) {
    PostQueryKind.following ||
    PostQueryKind.skills ||
    PostQueryKind.author ||
    PostQueryKind.keyword ||
    PostQueryKind.skill => values.isEmpty,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      other is PostQuery &&
      other.kind == kind &&
      other.values.length == values.length &&
      Iterable<int>.generate(values.length)
          .every((i) => other.values[i] == values[i]);

  @override
  int get hashCode => Object.hash(kind, Object.hashAll(values));
}

class PostPage {
  const PostPage(this.posts, this.cursor, {required this.hasMore});

  final List<CommunityPost> posts;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class PostMediaItem {
  const PostMediaItem({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class CommunityRepository {
  CommunityRepository(this._db, {Duration? writeTimeout})
    : _writeTimeout = writeTimeout ?? const Duration(seconds: 45);

  final FirebaseFirestore _db;

  final Duration _writeTimeout;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection(Collections.posts);

  DocumentReference<Map<String, dynamic>> _media(String postId, int index) =>
      _posts.doc(postId).collection(Collections.media).doc('$index');

  DocumentReference<Map<String, dynamic>> _videoChunk(
    String postId,
    int index,
  ) => _posts.doc(postId).collection(Collections.video).doc('$index');

  String newPostId(String authorId) => '${authorId}_${_posts.doc().id}';

  Future<bool> isPublished(String postId) =>
      guard(() => _existsOnServer(_posts.doc(postId)));

  Query<Map<String, dynamic>> _query(PostQuery query) {
    Query<Map<String, dynamic>> q = _posts;
    q = switch (query.kind) {
      PostQueryKind.forYou => q,
      PostQueryKind.projects => q.where('type', isEqualTo: PostType.project.id),
      PostQueryKind.following => q.where(
        'authorId',
        whereIn: query.values.take(CommunityLimits.maxFollowingInFeed).toList(),
      ),
      PostQueryKind.skills => q.where(
        'skillIds',
        arrayContainsAny: query.values.take(30).toList(),
      ),
      PostQueryKind.author => q.where(
        'authorId',
        isEqualTo: query.values.first,
      ),
      PostQueryKind.keyword => q.where(
        'keywords',
        arrayContains: query.values.first,
      ),
      PostQueryKind.skill => q.where(
        'skillIds',
        arrayContains: query.values.first,
      ),
    };
    return q.orderBy('createdAt', descending: true);
  }

  Future<PostPage> fetchPage(
    PostQuery query, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = CommunityLimits.feedPageSize,
  }) => guard(() async {
    if (query.isEmpty) return const PostPage([], null, hasMore: false);
    var q = _query(query);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.limit(limit).get();
    return PostPage(
      snap.docs.map(CommunityPost.fromDoc).toList(),
      snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  Stream<CommunityPost?> watchPost(String postId) => _posts
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? CommunityPost.fromDoc(doc) : null)
      .mapFailures();

  Future<CommunityPost?> getPost(String postId) => guard(() async {
    final doc = await _posts.doc(postId).get();
    return doc.exists ? CommunityPost.fromDoc(doc) : null;
  });

  Future<List<CommunityPost>> getPosts(List<String> ids) => guard(() async {
    final docs = await Future.wait(ids.map((id) => _posts.doc(id).get()));
    return [
      for (final doc in docs)
        if (doc.exists) CommunityPost.fromDoc(doc),
    ];
  });

  Future<PostMediaItem> getMedia(String postId, int index) => guard(() async {
    final doc = await _media(postId, index).get();
    final data = doc.data();
    final bytes = switch (data?['data']) {
      final Blob blob => blob.bytes,
      _ => null,
    };
    if (data == null || bytes == null || !PostImage.isAcceptable(bytes)) {
      throw const InvalidImageFailure();
    }
    return PostMediaItem(
      bytes: bytes,
      width: data['width'] as int? ?? 1,
      height: data['height'] as int? ?? 1,
    );
  });

  Future<Uint8List> getVideo(String postId, PostVideoInfo video) =>
      guard(() async {
        final docs = await Future.wait([
          for (var i = 0; i < video.chunks; i++) _videoChunk(postId, i).get(),
        ]);
        final out = BytesBuilder(copy: false);
        for (final doc in docs) {
          final bytes = switch (doc.data()?['data']) {
            final Blob blob => blob.bytes,
            _ => null,
          };
          if (bytes == null || bytes.length > PostVideo.chunkBytes) {
            throw const InvalidVideoFailure();
          }
          out.add(bytes);
        }
        final bytes = out.takeBytes();
        if (bytes.length != video.bytes || !PostVideo.isMp4(bytes)) {
          throw const InvalidVideoFailure();
        }
        return bytes;
      });

  Future<int> countByAuthor(String uid) => guard(() async {
    final snap = await _posts.where('authorId', isEqualTo: uid).count().get();
    return snap.count ?? 0;
  });

  Map<String, Object?> _content(PostDraft draft) {
    final description = draft.description.trim();
    return {
      'description': description,
      'type': draft.type.id,
      'skillIds': draft.skillIds.take(CommunityLimits.maxSkills).toList(),
      'tags': draft.tags.take(CommunityLimits.maxTags).toList(),
      'keywords': CommunityText.keywords(
        description: description,
        tags: draft.tags,
        skillIds: draft.skillIds,
      ),
    };
  }

  Future<int> postCooldownLeft(String uid, {DateTime? now}) => guard(() async {
    final doc = await _db.collection(Collections.rateLimits).doc(uid).get();
    final last = (doc.data()?['lastPostAt'] as Timestamp?)?.toDate();
    if (last == null) return 0;
    final elapsed = (now ?? DateTime.now()).difference(last);
    final left = CommunityLimits.postCooldown - elapsed;
    return left.isNegative ? 0 : left.inSeconds + 1;
  });

  Future<int> videoCooldownLeft(String uid, {DateTime? now}) => guard(() async {
    final doc = await _db.collection(Collections.rateLimits).doc(uid).get();
    final last = (doc.data()?['lastVideoAt'] as Timestamp?)?.toDate();
    if (last == null) return 0;
    final left =
        CommunityLimits.videoCooldown -
        (now ?? DateTime.now()).difference(last);
    return left.isNegative ? 0 : left.inMinutes + 1;
  });

  Future<void> createPost({
    required String postId,
    required String authorId,
    required PostDraft draft,
  }) => guard(() async {
    if (draft.isEmpty) throw const InvalidPostFailure();
    final video = draft.video;
    if (draft.images.length > CommunityLimits.maxImages ||
        draft.description.trim().length > CommunityLimits.maxDescription ||
        (video != null &&
            (draft.images.isNotEmpty ||
                !video.info.isValid ||
                !PostVideo.isMp4(video.bytes)))) {
      throw const InvalidPostFailure();
    }
    final postRef = _posts.doc(postId);
    final existing = await _existsOnServer(postRef);
    if (existing) return;

    final images = draft.storedImages;
    final batch = _db.batch()
      ..set(_db.collection(Collections.rateLimits).doc(authorId), {
        'lastPostAt': FieldValue.serverTimestamp(),
        'lastPostId': postId,
        if (video != null) 'lastVideoAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      ..set(postRef, {
        'authorId': authorId,
        ..._content(draft),
        'visibility': 'public',
        'mediaCount': images.length,
        'aspectRatios': [for (final image in images) image.aspectRatio],
        if (images.isNotEmpty) 'thumb': Blob(images.first.thumb),
        'video': ?video?.info.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    for (var i = 0; i < images.length; i++) {
      batch.set(_media(postId, i), {
        'data': Blob(images[i].bytes),
        'width': images[i].width,
        'height': images[i].height,
      });
    }
    if (video != null) {
      final chunks = PostVideo.split(video.bytes);
      for (var i = 0; i < chunks.length; i++) {
        batch.set(_videoChunk(postId, i), {'data': Blob(chunks[i])});
      }
    }
    final timeout =
        _writeTimeout +
        Duration(seconds: (video?.bytes.length ?? 0) ~/ (32 * 1024));
    try {
      await batch.commit().timeout(timeout);
    } on TimeoutException {
      throw const NetworkFailure();
    }
  });

  Future<bool> _existsOnServer(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final doc = await ref.get(const GetOptions(source: Source.server));
      return doc.exists;
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') return false;
      rethrow;
    }
  }

  Future<void> updatePost(String postId, PostDraft draft) => guard(() async {
    if (draft.description.trim().length > CommunityLimits.maxDescription) {
      throw const InvalidPostFailure();
    }
    await _posts
        .doc(postId)
        .update({..._content(draft), 'updatedAt': FieldValue.serverTimestamp()})
        .timeout(_writeTimeout, onTimeout: () => throw const NetworkFailure());
  });

  Future<void> deletePost(CommunityPost post) => guard(() async {
    final batch = _db.batch();
    for (var i = 0; i < post.mediaCount; i++) {
      batch.delete(_media(post.id, i));
    }
    if (post.mediaCount == 1) {
      for (var i = 0; i < PostVideo.maxChunks; i++) {
        batch.delete(_videoChunk(post.id, i));
      }
    }
    batch.delete(_posts.doc(post.id));
    await batch.commit().timeout(
      _writeTimeout,
      onTimeout: () => throw const NetworkFailure(),
    );
  });
}
