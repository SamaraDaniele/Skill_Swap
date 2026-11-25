import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../auth/auth_repository.dart';
import '../community/post_links.dart';
import '../profile/profile.dart';
import '../safety/safety.dart';
import '../safety/safety_ui.dart';
import 'matches.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String uid) async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(matchRepositoryProvider)
          .sendMessage(matchId: widget.matchId, senderId: uid, text: text);
      _input.clear();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _leaveWith(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
    context.pop();
  }

  Future<void> _onSafetyAction(
    _SafetyAction action,
    Match match,
    String uid,
    String name,
  ) async {
    final l10n = context.l10n;
    final otherId = match.otherUserId(uid);
    try {
      switch (action) {
        case _SafetyAction.unmatch:
          final confirmed = await confirmSafetyAction(
            context,
            title: l10n.unmatchConfirmTitle,
            body: l10n.unmatchConfirmBody,
            confirmLabel: l10n.unmatchAction,
          );
          if (!confirmed) return;
          await ref
              .read(matchRepositoryProvider)
              .closeMatch(matchId: match.id, uid: uid);
          _leaveWith(l10n.matchClosedDone);
        case _SafetyAction.block:
          final confirmed = await confirmSafetyAction(
            context,
            title: l10n.blockConfirmTitle(name),
            body: l10n.blockConfirmBody,
            confirmLabel: l10n.blockAction,
          );
          if (!confirmed) return;
          await ref
              .read(safetyRepositoryProvider)
              .block(me: uid, other: otherId, match: match);
          _leaveWith(l10n.blockDone);
        case _SafetyAction.report:
          final sent = await showReportSheet(
            context,
            me: uid,
            otherId: otherId,
            otherName: name,
            match: match,
          );
          if (sent) _leaveWith(l10n.reportDone);
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = ref.watch(authStateProvider).value ?? '';
    final match = ref
        .watch(matchesProvider)
        .value
        ?.where((m) => m.id == widget.matchId)
        .firstOrNull;
    final messages = ref.watch(messagesProvider(widget.matchId));
    final otherId = match?.otherUserId(uid);
    final other = otherId == null
        ? null
        : ref.watch(userProfileProvider(otherId)).value;
    final name = other?.name ?? '';
    final isClosed = match?.isClosed ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(name: name, photo: other?.photo, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (match != null)
            PopupMenuButton<_SafetyAction>(
              tooltip: l10n.moreOptions,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) => _onSafetyAction(action, match, uid, name),
              itemBuilder: (context) => [
                if (!isClosed)
                  PopupMenuItem(
                    value: _SafetyAction.unmatch,
                    child: _MenuRow(
                      icon: Icons.link_off_rounded,
                      label: l10n.unmatchAction,
                    ),
                  ),
                PopupMenuItem(
                  value: _SafetyAction.block,
                  child: _MenuRow(
                    icon: Icons.block_rounded,
                    label: l10n.blockAction,
                  ),
                ),
                PopupMenuItem(
                  value: _SafetyAction.report,
                  child: _MenuRow(
                    icon: Icons.flag_outlined,
                    label: l10n.reportAction,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ContentWidth(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: switch (messages) {
                  AsyncData(:final value) when value.isEmpty => MessageView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l10n.matchesNoMessages,
                    body: l10n.chatEmpty,
                  ),
                  AsyncData(:final value) => ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final message = value[index];
                      return _Bubble(
                        message: message,
                        isMine: message.senderId == uid,
                      );
                    },
                  ),
                  AsyncError(:final error) => ErrorView(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(messagesProvider(widget.matchId)),
                  ),
                  _ => const LoadingView(),
                },
              ),
              if (isClosed)
                _ClosedNotice(text: l10n.chatClosedNotice)
              else
                _Composer(
                  controller: _input,
                  isSending: _isSending,
                  onSend: () => _send(uid),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SafetyAction { unmatch, block, report }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: AppSpacing.md),
      Flexible(child: Text(label)),
    ],
  );
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  static final Map<String, DateFormat> _timeFormats = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = isMine ? scheme.onPrimaryContainer : scheme.onSurface;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = _timeFormats
        .putIfAbsent(locale, () => DateFormat.Hm(locale))
        .format(message.sentAt);
    const radius = Radius.circular(AppRadius.lg);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              math.min(
                MediaQuery.sizeOf(context).width,
                ContentWidth.readable,
              ) *
              0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMine
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: isMine
                  ? radius
                  : const Radius.circular(AppSpacing.xs),
              bottomRight: isMine
                  ? const Radius.circular(AppSpacing.xs)
                  : radius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(color: fg),
              ),
              if (PostLinks.findPostId(message.text) case final postId?)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: fg),
                  onPressed: () => context.push(AppRoutes.post(postId)),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(context.l10n.openSharedPost),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: MatchRepository.maxMessageLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.chatHint,
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
            builder: (context, _) {
              final enabled = !isSending && controller.text.trim().isNotEmpty;
              return IconButton.filled(
                tooltip: l10n.sendAction,
                iconSize: 22,
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}
