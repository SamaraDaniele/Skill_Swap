import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile.dart';
import '../comments_controller.dart';
import '../community_providers.dart';
import '../models.dart';
import 'community_widgets.dart';
import 'post_actions.dart';
import 'post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  CommunityComment? _replyTo;
  bool _sending = false;
  DateTime? _lastSent;

  final Set<String> _expanded = {};

  CommentsKey get _topKey => (postId: widget.postId, parentId: null);

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reply(CommunityComment comment) {
    setState(() => _replyTo = comment);
    _focus.requestFocus();
  }

  Future<void> _send(CommunityPost post) async {
    final l10n = context.l10n;
    final uid = ref.read(authStateProvider).value;
    final text = _text.text.trim();
    if (uid == null || text.isEmpty || _sending) return;
    final last = _lastSent;
    if (last != null &&
        DateTime.now().difference(last) < CommunityLimits.commentCooldown) {
      showAppSnackBar(context, l10n.commentTooFast);
      return;
    }
    setState(() => _sending = true);
    final parent = _replyTo;
    try {
      final comment = await ref
          .read(socialRepositoryProvider)
          .addComment(
            postId: post.id,
            postAuthorId: post.authorId,
            uid: uid,
            text: text,
            parent: parent,
          );
      _lastSent = DateTime.now();
      if (!mounted) return;
      final parentId = comment.parentId;
      if (parentId == null) {
        ref.read(commentsProvider(_topKey).notifier).append(comment);
      } else {
        final key = (postId: post.id, parentId: parentId);
        setState(() => _expanded.add(parentId));
        if (ref.read(commentsProvider(key).exists)) {
          ref.read(commentsProvider(key).notifier).append(comment);
        }
      }
      ref.invalidate(commentCountProvider(post.id));
      _text.clear();
      setState(() => _replyTo = null);
    } catch (error) {
      if (mounted) showAppSnackBar(context, l10n.failureMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final post = ref.watch(postProvider(widget.postId));
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.postTitle)),
      body: switch (post) {
        AsyncData(value: final post?) when !blocked.contains(post.authorId) =>
          Column(
            children: [
              Expanded(
                child: ContentWidth(
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        sliver: SliverToBoxAdapter(
                          child: PostCard(
                            post: post,
                            detailed: true,
                            onComment: _focus.requestFocus,
                            onRemoved: () {
                              if (context.canPop()) context.pop();
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.commentsTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                      _CommentList(
                        commentsKey: _topKey,
                        post: post,
                        expanded: _expanded,
                        onToggleReplies: (id) => setState(
                          () => _expanded.contains(id)
                              ? _expanded.remove(id)
                              : _expanded.add(id),
                        ),
                        onReply: _reply,
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxl),
                      ),
                    ],
                  ),
                ),
              ),
              _CommentComposer(
                controller: _text,
                focusNode: _focus,
                sending: _sending,
                replyingTo: _replyTo,
                onCancelReply: () => setState(() => _replyTo = null),
                onSend: () => _send(post),
              ),
            ],
          ),
        AsyncData() => MessageView(
          icon: Icons.search_off_rounded,
          title: l10n.postNotFoundTitle,
          body: l10n.postNotFoundBody,
          actionLabel: l10n.backToCommunity,
          onAction: () => context.go(AppRoutes.community),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(postProvider(widget.postId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _CommentList extends ConsumerWidget {
  const _CommentList({
    required this.commentsKey,
    required this.post,
    required this.expanded,
    required this.onToggleReplies,
    required this.onReply,
  });

  final CommentsKey commentsKey;
  final CommunityPost post;
  final Set<String> expanded;
  final ValueChanged<String> onToggleReplies;
  final ValueChanged<CommunityComment> onReply;

  bool get _isReplies => commentsKey.parentId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(commentsProvider(commentsKey));
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    Widget wrap(Widget child) =>
        _isReplies ? child : SliverToBoxAdapter(child: child);
    switch (list) {
      case AsyncData(:final value):
        final comments = value.comments
            .where((c) => !blocked.contains(c.authorId))
            .toList();
        if (comments.isEmpty && !value.hasMore) {
          return wrap(
            _isReplies
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      l10n.commentsEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
          );
        }
        final children = [
          for (final comment in comments) ...[
            _CommentTile(
              comment: comment,
              post: post,
              onReply: () => onReply(comment),
              onDeleted: () => ref
                  .read(commentsProvider(commentsKey).notifier)
                  .remove(comment.id),
            ),
            if (!_isReplies)
              _RepliesSection(
                comment: comment,
                post: post,
                expanded: expanded.contains(comment.id),
                onToggle: () => onToggleReplies(comment.id),
                onReply: onReply,
              ),
          ],
          if (value.hasMore || value.loadMoreFailed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: value.isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => ref
                            .read(commentsProvider(commentsKey).notifier)
                            .loadMore(),
                        child: Text(
                          value.loadMoreFailed
                              ? l10n.loadMoreFailed
                              : l10n.loadMoreComments,
                        ),
                      ),
              ),
            ),
        ];
        if (_isReplies) return Column(children: children);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.list(children: children),
        );
      case AsyncError(:final error):
        return wrap(
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(l10n.failureMessage(error), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(commentsProvider(commentsKey)),
                  child: Text(l10n.retryAction),
                ),
              ],
            ),
          ),
        );
      default:
        return wrap(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
    }
  }
}

class _RepliesSection extends StatelessWidget {
  const _RepliesSection({
    required this.comment,
    required this.post,
    required this.expanded,
    required this.onToggle,
    required this.onReply,
  });

  final CommunityComment comment;
  final CommunityPost post;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<CommunityComment> onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            onPressed: onToggle,
            child: Text(expanded ? l10n.hideReplies : l10n.showReplies),
          ),
          if (expanded)
            _CommentList(
              commentsKey: (postId: post.id, parentId: comment.id),
              post: post,
              expanded: const {},
              onToggleReplies: (_) {},
              onReply: onReply,
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    required this.comment,
    required this.post,
    required this.onReply,
    required this.onDeleted,
  });

  final CommunityComment comment;
  final CommunityPost post;
  final VoidCallback onReply;
  final VoidCallback onDeleted;

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    final canDelete = comment.authorId == me || post.authorId == me;
    final canReport = comment.authorId != me;
    final action = await showActionSheet<String>(
      context,
      actions: (context) => [
        if (canDelete)
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(l10n.deleteCommentAction),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        if (canReport)
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.reportCommentAction),
            onTap: () => Navigator.of(context).pop('report'),
          ),
      ],
    );
    if (!context.mounted) return;
    if (action == 'report') {
      await showContentReportSheet(
        context,
        authorId: comment.authorId,
        postId: post.id,
        commentId: comment.id,
      );
    } else if (action == 'delete') {
      try {
        await ref.read(socialRepositoryProvider).deleteComment(comment);
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(context, l10n.failureMessage(error));
        }
        return;
      }
      onDeleted();
      ref.invalidate(commentCountProvider(post.id));
      if (context.mounted) showAppSnackBar(context, l10n.commentDeleted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final author = ref.watch(userProfileProvider(comment.authorId)).value;
    final name = author?.name ?? l10n.memberFallbackName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l10n.openMemberProfile(name),
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(AppRoutes.member(comment.authorId)),
              child: RingAvatar(name: name, photo: author?.photo, size: 42),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: '  ${relativeTime(context, comment.createdAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(height: 1.35)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(64, 40),
                      foregroundColor: AppColors.neon,
                    ),
                    onPressed: onReply,
                    child: Text(l10n.replyAction),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commentMenuTooltip,
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onPressed: () => _menu(context, ref),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends ConsumerWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final CommunityComment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentProfileProvider).value;
    final replyName = replyingTo == null
        ? null
        : ref.watch(userProfileProvider(replyingTo!.authorId)).value?.name ??
              l10n.memberFallbackName;
    return Material(
      color: AppColors.surface1,
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyName != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.replyingTo(replyName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.cancelAction,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: onCancelReply,
                      ),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (me != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.sm,
                          bottom: 4,
                        ),
                        child: ProfileAvatar(
                          name: me.name,
                          photo: me.photo,
                          size: 40,
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: CommunityLimits.maxComment,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.commentHint,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => IconButton.filled(
                        tooltip: l10n.sendAction,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.neon,
                          foregroundColor: AppColors.black,
                        ),
                        onPressed: !sending && controller.text.trim().isNotEmpty
                            ? onSend
                            : null,
                        icon: sending
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
