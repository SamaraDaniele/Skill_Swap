import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../community_providers.dart';
import '../models.dart';
import 'post_card.dart';

class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  final List<CommunityPost> _posts = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _reload() async {
    if (_loading) return;
    setState(() {
      _posts.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null || _loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(socialRepositoryProvider)
          .fetchSaved(uid, cursor: _cursor);
      final posts = await ref
          .read(communityRepositoryProvider)
          .getPosts(page.ids);
      if (!mounted) return;
      setState(() {
        final known = _posts.map((p) => p.id).toSet();
        _posts.addAll(posts.where((p) => !known.contains(p.id)));
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    final posts = _posts.where((p) => !blocked.contains(p.authorId)).toList();
    final Widget body;
    if (_error != null && _posts.isEmpty) {
      body = ErrorView(error: _error!, onRetry: _reload);
    } else if (posts.isEmpty && _loading) {
      body = const LoadingView();
    } else if (posts.isEmpty && !_hasMore) {
      body = MessageView(
        icon: Icons.bookmark_border_rounded,
        title: l10n.savedEmptyTitle,
        body: l10n.savedEmptyBody,
      );
    } else {
      body = RefreshIndicator(
        color: AppColors.neon,
        onRefresh: _reload,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index == posts.length) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _hasMore
                  ? TextButton(
                      onPressed: _loadMore,
                      child: Text(
                        _error == null
                            ? l10n.loadMoreAction
                            : l10n.loadMoreFailed,
                      ),
                    )
                  : const SizedBox(height: AppSpacing.xl);
            }
            final post = posts[index];
            return Padding(
              key: ValueKey(post.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: PostCard(
                post: post,
                onRemoved: () =>
                    setState(() => _posts.removeWhere((p) => p.id == post.id)),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedTitle)),
      body: ContentWidth(child: body),
    );
  }
}
