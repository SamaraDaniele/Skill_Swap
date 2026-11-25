import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../matches/matches.dart';
import '../../profile/profile.dart';
import '../../safety/safety.dart';
import '../../safety/safety_ui.dart';
import '../community_providers.dart';
import '../learn_request.dart';
import '../models.dart';
import '../post_links.dart';

Future<void> showPostMenu(
  BuildContext context,
  WidgetRef ref, {
  required CommunityPost post,
  VoidCallback? onRemoved,
}) async {
  final l10n = context.l10n;
  final me = ref.read(authStateProvider).value;
  if (me == null) return;
  final isMine = post.authorId == me;
  final authorName =
      ref.read(userProfileProvider(post.authorId)).value?.name ??
      l10n.memberFallbackName;
  final action = await showActionSheet<_PostAction>(
    context,
    actions: (context) => [
      if (isMine) ...[
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.editPostAction),
          onTap: () => Navigator.of(context).pop(_PostAction.edit),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.deletePostAction),
          onTap: () => Navigator.of(context).pop(_PostAction.delete),
        ),
      ],
      ListTile(
        leading: const Icon(Icons.link_rounded),
        title: Text(l10n.copyLinkAction),
        onTap: () => Navigator.of(context).pop(_PostAction.copyLink),
      ),
      if (!isMine) ...[
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.reportPostAction),
          onTap: () => Navigator.of(context).pop(_PostAction.report),
        ),
        ListTile(
          leading: Icon(
            Icons.block_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.blockMemberAction(authorName)),
          onTap: () => Navigator.of(context).pop(_PostAction.block),
        ),
      ],
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _PostAction.edit:
      await context.push(AppRoutes.editPost(post.id));
    case _PostAction.delete:
      await _deletePost(context, ref, post, onRemoved);
    case _PostAction.copyLink:
      await copyPostLink(context, post.id);
    case _PostAction.report:
      await showContentReportSheet(
        context,
        authorId: post.authorId,
        postId: post.id,
      );
    case _PostAction.block:
      final blocked = await blockMember(
        context,
        ref,
        otherId: post.authorId,
        otherName: authorName,
      );
      if (blocked) onRemoved?.call();
  }
}

enum _PostAction { edit, delete, copyLink, report, block }

Future<void> _deletePost(
  BuildContext context,
  WidgetRef ref,
  CommunityPost post,
  VoidCallback? onRemoved,
) async {
  final l10n = context.l10n;
  final confirmed = await confirmSafetyAction(
    context,
    title: l10n.deletePostTitle,
    body: l10n.deletePostBody,
    confirmLabel: l10n.deletePostAction,
  );
  if (!confirmed || !context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await container.read(communityRepositoryProvider).deletePost(post);
  } catch (error) {
    showMessage(messenger, l10n.failureMessage(error));
    return;
  }
  removePostEverywhere(container, post.id);
  onRemoved?.call();
  showMessage(messenger, l10n.postDeleted);
}

void showMessage(ScaffoldMessengerState messenger, String message) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void removePostEverywhere(ProviderContainer container, String postId) {
  container.invalidate(memberStatsProvider);
  for (final query in container.read(activePostQueriesProvider).toList()) {
    if (container.read(postListProvider(query).exists)) {
      container.read(postListProvider(query).notifier).remove(postId);
    }
  }
}

Future<void> copyPostLink(BuildContext context, String postId) async {
  await Clipboard.setData(ClipboardData(text: PostLinks.forPost(postId)));
  if (context.mounted) showAppSnackBar(context, context.l10n.linkCopied);
}

Future<bool> blockMember(
  BuildContext context,
  WidgetRef ref, {
  required String otherId,
  required String otherName,
}) async {
  final l10n = context.l10n;
  final me = ref.read(authStateProvider).value;
  if (me == null || me == otherId) return false;
  final confirmed = await confirmSafetyAction(
    context,
    title: l10n.blockConfirmTitle(otherName),
    body: l10n.communityBlockBody(otherName),
    confirmLabel: l10n.blockAction,
  );
  if (!confirmed || !context.mounted) return false;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final match = await findMatch(container, me, otherId);
    await container
        .read(safetyRepositoryProvider)
        .block(me: me, other: otherId, match: match);
  } catch (error) {
    showMessage(messenger, l10n.failureMessage(error));
    return false;
  }
  showMessage(messenger, l10n.blockDone);
  return true;
}

Future<void> showContentReportSheet(
  BuildContext context, {
  required String authorId,
  required String postId,
  String? commentId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ContentReportSheet(
      authorId: authorId,
      postId: postId,
      commentId: commentId,
    ),
  );
  if (sent == true && context.mounted) {
    showAppSnackBar(context, context.l10n.contentReportDone);
  }
}

class _ContentReportSheet extends ConsumerStatefulWidget {
  const _ContentReportSheet({
    required this.authorId,
    required this.postId,
    required this.commentId,
  });

  final String authorId;
  final String postId;
  final String? commentId;

  @override
  ConsumerState<_ContentReportSheet> createState() =>
      _ContentReportSheetState();
}

class _ContentReportSheetState extends ConsumerState<_ContentReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _submitted = false;
  bool _sending = false;

  static const _reasons = [
    ReportReason.spam,
    ReportReason.harassment,
    ReportReason.offensive,
    ReportReason.scam,
    ReportReason.inappropriate,
    ReportReason.other,
  ];

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    final reason = _reason;
    final me = ref.read(authStateProvider).value;
    if (reason == null || me == null || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .reportContent(
            me: me,
            authorId: widget.authorId,
            postId: widget.postId,
            commentId: widget.commentId,
            reason: reason,
            details: _details.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.commentId == null
                  ? l10n.reportPostTitle
                  : l10n.reportCommentTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.contentReportIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in _reasons)
                    RadioListTile<ReportReason>(
                      value: reason,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason.label(l10n)),
                    ),
                ],
              ),
            ),
            if (_submitted && _reason == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.reportPickReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            TextField(
              controller: _details,
              maxLength: SafetyRepository.maxDetailsLength,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.reportDetailsLabel,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.contentReportSubmit,
              isLoading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showShareSheet(
  BuildContext context, {
  required CommunityPost post,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ShareSheet(post: post),
);

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.post});

  final CommunityPost post;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  String? _sendingTo;

  Future<void> _send(Match match, String name) async {
    final l10n = context.l10n;
    final me = ref.read(authStateProvider).value;
    if (me == null || _sendingTo != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sharePostTitle(name)),
        content: Text(l10n.sharePostBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sendAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sendingTo = match.id);
    try {
      await ref
          .read(matchRepositoryProvider)
          .sendMessage(
            matchId: match.id,
            senderId: me,
            text: l10n.sharedPostMessage(PostLinks.forPost(widget.post.id)),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, l10n.postSharedTo(name));
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendingTo = null);
      showAppSnackBar(context, l10n.failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value;
    final matches = ref.watch(matchesProvider);
    final active = matches.value?.where((m) => !m.isClosed).toList() ?? [];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.md,
            ),
            child: Text(
              l10n.shareAction,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text(l10n.copyLinkAction),
            onTap: () async {
              await copyPostLink(context, widget.post.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.sendInChat,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (matches.isLoading && active.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: LoadingView(),
            )
          else if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.shareNoChats,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final match in active)
              if (me != null)
                _ChatTarget(
                  otherId: match.otherUserId(me),
                  sending: _sendingTo == match.id,
                  onTap: (name) => _send(match, name),
                ),
        ],
      ),
    );
  }
}

class _ChatTarget extends ConsumerWidget {
  const _ChatTarget({
    required this.otherId,
    required this.sending,
    required this.onTap,
  });

  final String otherId;
  final bool sending;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(otherId)).value;
    final name = profile?.name ?? context.l10n.memberFallbackName;
    return ListTile(
      leading: ProfileAvatar(name: name, photo: profile?.photo, size: 44),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: sending
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send_outlined),
      onTap: sending ? null : () => onTap(name),
    );
  }
}
