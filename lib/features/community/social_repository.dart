import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import 'models.dart';

class CommentPage {
  const CommentPage(this.comments, this.cursor, {required this.hasMore});

  final List<CommunityComment> comments;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class IdPage {
  const IdPage(this.ids, this.cursor, {required this.hasMore});

  final List<String> ids;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class SocialRepository {
  const SocialRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _post(String postId) =>
      _db.collection(Collections.posts).doc(postId);

  DocumentReference<Map<String, dynamic>> _like(String postId, String uid) =>
      _post(postId).collection(Collections.postLikes).doc(uid);

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _post(postId).collection(Collections.comments);

  DocumentReference<Map<String, dynamic>> _saved(String uid, String postId) =>
      _db
          .collection(Collections.users)
          .doc(uid)
          .collection(Collections.saved)
          .doc(postId);

  DocumentReference<Map<String, dynamic>> _follow(String from, String to) =>
      _db.collection(Collections.follows).doc('${from}_$to');

  CollectionReference<Map<String, dynamic>> _notifications(String uid) => _db
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.notifications);

  DocumentReference<Map<String, dynamic>> _rate(String uid) =>
      _db.collection(Collections.rateLimits).doc(uid);

  Future<int> _count(Query<Map<String, dynamic>> query) async =>
      (await query.count().get()).count ?? 0;

  Future<void> _notify({
    required String recipient,
    required String id,
    required NotificationType type,
    required String actor,
    String? postId,
    String? commentId,
  }) async {
    if (recipient == actor || recipient.isEmpty) return;
    try {
      await _notifications(recipient).doc(id).set({
        'type': type.name,
        'actorId': actor,
        'postId': postId,
        'commentId': commentId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Object catch (error) {
      if (kDebugMode) debugPrint('notification $id not sent: $error');
    }
  }

  Future<void> _withdraw(String recipient, String id) async {
    try {
      await _notifications(recipient).doc(id).delete();
    } on Object catch (error) {
      if (kDebugMode) debugPrint('notification $id not withdrawn: $error');
    }
  }

  Future<bool> isLiked(String postId, String uid) =>
      guard(() async => (await _like(postId, uid).get()).exists);

  Future<int> likeCount(String postId) =>
      guard(() => _count(_post(postId).collection(Collections.postLikes)));

  Future<void> like({
    required String postId,
    required String uid,
    required String authorId,
  }) => guard(() async {
    await _like(postId, uid).set({'createdAt': FieldValue.serverTimestamp()});
    unawaited(
      _notify(
        recipient: authorId,
        id: 'like_${postId}_$uid',
        type: NotificationType.like,
        actor: uid,
        postId: postId,
      ),
    );
  });

  Future<void> unlike({
    required String postId,
    required String uid,
    required String authorId,
  }) => guard(() async {
    await _like(postId, uid).delete();
    if (authorId != uid) unawaited(_withdraw(authorId, 'like_${postId}_$uid'));
  });

  Future<int> commentCount(String postId) =>
      guard(() => _count(_comments(postId)));

  Future<CommentPage> fetchComments(
    String postId, {
    String? parentId,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = CommunityLimits.commentPageSize,
  }) => guard(() async {
    var q =
        (parentId == null
                ? _comments(postId).where('parentId', isNull: true)
                : _comments(postId).where('parentId', isEqualTo: parentId))
            .orderBy('createdAt');
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.limit(limit).get();
    return CommentPage(
      snap.docs.map((d) => CommunityComment.fromDoc(postId, d)).toList(),
      snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  Future<CommunityComment> addComment({
    required String postId,
    required String postAuthorId,
    required String uid,
    required String text,
    CommunityComment? parent,
  }) => guard(() async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > CommunityLimits.maxComment) {
      throw const InvalidPostFailure();
    }
    final parentId = parent == null ? null : (parent.parentId ?? parent.id);
    final ref = _comments(postId).doc();
    await (_db.batch()
          ..set(_rate(uid), {
            'lastCommentAt': FieldValue.serverTimestamp(),
            'lastCommentKey': '${postId}_${ref.id}',
          }, SetOptions(merge: true))
          ..set(ref, {
            'authorId': uid,
            'text': trimmed,
            'parentId': parentId,
            'createdAt': FieldValue.serverTimestamp(),
          }))
        .commit();
    if (parent == null) {
      unawaited(
        _notify(
          recipient: postAuthorId,
          id: 'comment_${ref.id}',
          type: NotificationType.comment,
          actor: uid,
          postId: postId,
          commentId: ref.id,
        ),
      );
    } else {
      unawaited(
        _notify(
          recipient: parent.authorId,
          id: 'reply_${ref.id}',
          type: NotificationType.reply,
          actor: uid,
          postId: postId,
          commentId: ref.id,
        ),
      );
    }
    return CommunityComment(
      id: ref.id,
      postId: postId,
      authorId: uid,
      text: trimmed,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
  });

  Future<void> deleteComment(CommunityComment comment) => guard(() async {
    final batch = _db.batch()
      ..delete(_comments(comment.postId).doc(comment.id));
    if (!comment.isReply) {
      final replies = await _comments(comment.postId)
          .where('parentId', isEqualTo: comment.id)
          .limit(400)
          .get();
      for (final reply in replies.docs) {
        batch.delete(reply.reference);
      }
    }
    await batch.commit();
  });

  Stream<bool> watchSaved(String uid, String postId) =>
      _saved(uid, postId).snapshots().map((doc) => doc.exists).mapFailures();

  Future<void> setSaved({
    required String uid,
    required String postId,
    required bool saved,
  }) => guard(
    () => saved
        ? _saved(uid, postId).set({'createdAt': FieldValue.serverTimestamp()})
        : _saved(uid, postId).delete(),
  );

  Future<IdPage> fetchSaved(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = CommunityLimits.feedPageSize,
  }) => guard(() async {
    var q = _db
        .collection(Collections.users)
        .doc(uid)
        .collection(Collections.saved)
        .orderBy('createdAt', descending: true);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.limit(limit).get();
    return IdPage(
      snap.docs.map((d) => d.id).toList(),
      snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  Stream<bool> watchFollowing(String me, String other) =>
      _follow(me, other).snapshots().map((doc) => doc.exists).mapFailures();

  Future<void> follow(String me, String other) => guard(() async {
    if (me == other) throw const PermissionFailure();
    await _follow(me, other).set({
      'followerId': me,
      'followingId': other,
      'createdAt': FieldValue.serverTimestamp(),
    });
    unawaited(
      _notify(
        recipient: other,
        id: 'follow_$me',
        type: NotificationType.follow,
        actor: me,
      ),
    );
  });

  Future<void> unfollow(String me, String other) => guard(() async {
    await _follow(me, other).delete();
    unawaited(_withdraw(other, 'follow_$me'));
  });

  Future<int> followerCount(String uid) => guard(
    () => _count(
      _db.collection(Collections.follows).where('followingId', isEqualTo: uid),
    ),
  );

  Future<int> followingCount(String uid) => guard(
    () => _count(
      _db.collection(Collections.follows).where('followerId', isEqualTo: uid),
    ),
  );

  Future<IdPage> fetchFollows(
    String uid, {
    required bool followers,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 20,
  }) => guard(() async {
    var q = _db
        .collection(Collections.follows)
        .where(followers ? 'followingId' : 'followerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
    if (cursor != null) q = q.startAfterDocument(cursor);
    final snap = await q.limit(limit).get();
    final key = followers ? 'followerId' : 'followingId';
    return IdPage(
      snap.docs.map((d) => d.data()[key]).whereType<String>().toList(),
      snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  Stream<List<String>> watchFollowingIds(String uid) => _db
      .collection(Collections.follows)
      .where('followerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(CommunityLimits.maxFollowingInFeed)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => d.data()['followingId'])
            .whereType<String>()
            .toList(),
      )
      .mapFailures();

  Stream<List<CommunityNotification>> watchNotifications(String uid) =>
      _notifications(uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map(CommunityNotification.fromDoc).nonNulls.toList(),
          )
          .mapFailures();

  Stream<int> watchUnreadCount(String uid) =>
      _notifications(uid)
          .where('read', isEqualTo: false)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.length)
          .mapFailures();

  Future<void> markRead(String uid, Iterable<String> ids) => guard(() async {
    final results = await Future.wait(
      ids.map(
        (id) =>
            _notifications(uid)
                .doc(id)
                .update({'read': true})
                .then((_) => true, onError: (Object _) => false),
      ),
    );
    if (results.isNotEmpty && !results.contains(true)) {
      throw const NetworkFailure();
    }
  });

  Future<void> deleteNotification(String uid, String id) =>
      guard(() => _notifications(uid).doc(id).delete());

  Future<void> notifyLearnRequest({
    required String uid,
    required String authorId,
    String? postId,
  }) => _notify(
    recipient: authorId,
    id: 'learn_$uid',
    type: NotificationType.learn,
    actor: uid,
    postId: postId,
  );
}
