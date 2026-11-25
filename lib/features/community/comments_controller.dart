import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'community_providers.dart';
import 'models.dart';

typedef CommentsKey = ({String postId, String? parentId});

class CommentListState {
  const CommentListState({
    required this.comments,
    required this.cursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<CommunityComment> comments;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  CommentListState copyWith({
    List<CommunityComment>? comments,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => CommentListState(
    comments: comments ?? this.comments,
    cursor: cursor ?? this.cursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsController, CommentListState, CommentsKey>(
      CommentsController.new,
      retry: communityRetry,
    );

class CommentsController extends AsyncNotifier<CommentListState> {
  CommentsController(this.key);

  final CommentsKey key;

  @override
  Future<CommentListState> build() async {
    final page = await ref
        .read(socialRepositoryProvider)
        .fetchComments(key.postId, parentId: key.parentId);
    return CommentListState(
      comments: page.comments,
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
          .read(socialRepositoryProvider)
          .fetchComments(
            key.postId,
            parentId: key.parentId,
            cursor: current.cursor,
          );
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final known = latest.comments.map((c) => c.id).toSet();
      state = AsyncData(
        latest.copyWith(
          comments: [
            ...latest.comments,
            ...page.comments.where((c) => !known.contains(c.id)),
          ],
          cursor: page.cursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          (state.value ?? current).copyWith(
            isLoadingMore: false,
            loadMoreFailed: true,
          ),
        );
      }
    }
  }

  void append(CommunityComment comment) {
    final current = state.value;
    if (current == null || current.comments.any((c) => c.id == comment.id)) {
      return;
    }
    state = AsyncData(
      current.copyWith(comments: [...current.comments, comment]),
    );
  }

  void remove(String commentId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        comments: current.comments.where((c) => c.id != commentId).toList(),
      ),
    );
  }
}
