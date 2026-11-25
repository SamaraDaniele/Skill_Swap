import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/firebase_providers.dart';
import '../auth/auth_repository.dart';
import '../profile/profile.dart';
import 'community_repository.dart';
import 'models.dart';
import 'social_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.watch(firestoreProvider)),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(firestoreProvider)),
);

Duration? communityRetry(int retryCount, Object error) =>
    mapToFailure(error) is NetworkFailure && retryCount < 3
    ? Duration(seconds: 2 << retryCount)
    : null;

void cacheFor(Ref ref, Duration duration) {
  final link = ref.keepAlive();
  Timer? timer;
  ref
    ..onCancel(() => timer = Timer(duration, link.close))
    ..onResume(() => timer?.cancel())
    ..onDispose(() => timer?.cancel());
}

String? _uid(Ref ref) => ref.watch(authStateProvider).value;

final blockedIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(const {});
  return ref
      .watch(firestoreProvider)
      .collection(Collections.blocks)
      .where('blocker', isEqualTo: uid)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => d.data()['blocked'])
            .whereType<String>()
            .toSet(),
      )
      .mapFailures();
}, retry: communityRetry);

final followingIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(const []);
  return ref.watch(socialRepositoryProvider).watchFollowingIds(uid);
}, retry: communityRetry);

enum FeedTab { forYou, following, skills, projects }

final feedQueryProvider = FutureProvider.autoDispose.family<PostQuery, FeedTab>(
  (ref, tab) async {
    switch (tab) {
      case FeedTab.forYou:
        return PostQuery.forYou;
      case FeedTab.projects:
        return PostQuery.projects;
      case FeedTab.following:
        return PostQuery.following(
          await ref.watch(followingIdsProvider.future),
        );
      case FeedTab.skills:
        final key = await ref.watch(
          currentProfileProvider.selectAsync(
            (p) => {...?p?.learn, ...?p?.teach}.join(','),
          ),
        );
        return PostQuery.skills(
          key.isEmpty ? const [] : key.split(',').take(30).toList(),
        );
    }
  },
  retry: communityRetry,
);

class PostListState {
  const PostListState({
    required this.posts,
    required this.cursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<CommunityPost> posts;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  PostListState copyWith({
    List<CommunityPost>? posts,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => PostListState(
    posts: posts ?? this.posts,
    cursor: cursor ?? this.cursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final activePostQueriesProvider = Provider<Set<PostQuery>>((ref) => {});

final postListProvider = AsyncNotifierProvider.autoDispose
    .family<PostListController, PostListState, PostQuery>(
      PostListController.new,
      retry: communityRetry,
    );

class PostListController extends AsyncNotifier<PostListState> {
  PostListController(this.query);

  final PostQuery query;

  @override
  Future<PostListState> build() async {
    cacheFor(ref, const Duration(minutes: 5));
    final active = ref.read(activePostQueriesProvider)..add(query);
    ref.onDispose(() => active.remove(query));
    final page = await ref.read(communityRepositoryProvider).fetchPage(query);
    return PostListState(
      posts: page.posts,
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(communityRepositoryProvider)
          .fetchPage(query, cursor: current.cursor);
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final known = latest.posts.map((p) => p.id).toSet();
      state = AsyncData(
        latest.copyWith(
          posts: [
            ...latest.posts,
            ...page.posts.where((p) => !known.contains(p.id)),
          ],
          cursor: page.cursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
        ),
      );
    }
  }

  void remove(String postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        posts: current.posts.where((p) => p.id != postId).toList(),
      ),
    );
  }
}

final postProvider = StreamProvider.autoDispose.family<CommunityPost?, String>(
  (ref, postId) => ref.watch(communityRepositoryProvider).watchPost(postId),
  retry: communityRetry,
);

typedef MediaKey = ({String postId, int index});

final postMediaProvider = FutureProvider.autoDispose
    .family<PostMediaItem, MediaKey>((ref, key) {
      cacheFor(ref, const Duration(minutes: 3));
      return ref
          .read(communityRepositoryProvider)
          .getMedia(key.postId, key.index);
    }, retry: communityRetry);

class LikeState {
  const LikeState({required this.liked, required this.count});

  final bool liked;
  final int count;
}

final likeControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LikeController, LikeState, String>(
      LikeController.new,
      retry: communityRetry,
    );

class LikeController extends AsyncNotifier<LikeState> {
  LikeController(this.postId);

  final String postId;
  bool _busy = false;

  @override
  Future<LikeState> build() async {
    cacheFor(ref, const Duration(minutes: 3));
    final uid = ref.watch(authStateProvider).value;
    final social = ref.read(socialRepositoryProvider);
    final results = await Future.wait([
      if (uid != null) social.isLiked(postId, uid) else Future.value(false),
      social.likeCount(postId),
    ]);
    return LikeState(liked: results[0] as bool, count: results[1] as int);
  }

  Future<void> toggle({required String authorId}) async {
    final uid = ref.read(authStateProvider).value;
    final current = state.value;
    if (uid == null || current == null || _busy) return;
    _busy = true;
    final liked = !current.liked;
    state = AsyncData(
      LikeState(
        liked: liked,
        count: (current.count + (liked ? 1 : -1)).clamp(0, 1 << 30),
      ),
    );
    final social = ref.read(socialRepositoryProvider);
    try {
      liked
          ? await social.like(postId: postId, uid: uid, authorId: authorId)
          : await social.unlike(postId: postId, uid: uid, authorId: authorId);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    } finally {
      _busy = false;
    }
  }
}

final commentCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  postId,
) {
  cacheFor(ref, const Duration(minutes: 3));
  return ref.read(socialRepositoryProvider).commentCount(postId);
}, retry: communityRetry);

final savedProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  postId,
) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(false);
  return ref.watch(socialRepositoryProvider).watchSaved(uid, postId);
}, retry: communityRetry);

final isFollowingProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  otherId,
) {
  final uid = _uid(ref);
  if (uid == null || uid == otherId) return Stream.value(false);
  return ref.watch(socialRepositoryProvider).watchFollowing(uid, otherId);
}, retry: communityRetry);

typedef MemberStats = ({int posts, int followers, int following});

final memberStatsProvider = FutureProvider.autoDispose
    .family<MemberStats, String>((ref, uid) async {
      final social = ref.read(socialRepositoryProvider);
      final counts = await Future.wait([
        ref.read(communityRepositoryProvider).countByAuthor(uid),
        social.followerCount(uid),
        social.followingCount(uid),
      ]);
      return (posts: counts[0], followers: counts[1], following: counts[2]);
    }, retry: communityRetry);

final notificationsProvider =
    StreamProvider.autoDispose<List<CommunityNotification>>((ref) {
      final uid = _uid(ref);
      if (uid == null) return Stream.value(const []);
      return ref.watch(socialRepositoryProvider).watchNotifications(uid);
    }, retry: communityRetry);

final unreadNotificationsProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = _uid(ref);
  if (uid == null) return Stream.value(0);
  return ref.watch(socialRepositoryProvider).watchUnreadCount(uid);
}, retry: communityRetry);
