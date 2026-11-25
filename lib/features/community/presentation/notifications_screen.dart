import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile.dart';
import '../community_providers.dart';
import '../models.dart';
import 'community_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _hidden = {};

  Future<void> _markAllRead(List<CommunityNotification> items) async {
    final uid = ref.read(authStateProvider).value;
    final unread = items.where((n) => !n.read).map((n) => n.id).toList();
    if (uid == null || unread.isEmpty) return;
    try {
      await ref.read(socialRepositoryProvider).markRead(uid, unread);
    } catch (error) {
      if (mounted) showAppSnackBar(context, context.l10n.failureMessage(error));
    }
  }

  Future<void> _delete(CommunityNotification item) async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final l10n = context.l10n;
    setState(() => _hidden.add(item.id));
    try {
      await ref.read(socialRepositoryProvider).deleteNotification(uid, item.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _hidden.remove(item.id));
      showAppSnackBar(context, l10n.failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(notificationsProvider);
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    final roomy =
        MediaQuery.sizeOf(context).width /
            MediaQuery.textScalerOf(context).scale(1) >=
        300;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (items.value case final list? when list.any((n) => !n.read))
            roomy
                ? TextButton(
                    onPressed: () => _markAllRead(list),
                    child: Text(l10n.markAllReadAction),
                  )
                : IconButton(
                    tooltip: l10n.markAllReadAction,
                    icon: const Icon(Icons.done_all_rounded),
                    onPressed: () => _markAllRead(list),
                  ),
        ],
      ),
      body: ContentWidth(
        child: switch (items) {
          AsyncValue(:final value?) => () {
            final visible = value
                .where(
                  (n) =>
                      !blocked.contains(n.actorId) && !_hidden.contains(n.id),
                )
                .toList();
            if (visible.isEmpty) {
              return MessageView(
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsEmptyTitle,
                body: l10n.notificationsEmptyBody,
              );
            }
            return ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.outlineSoft),
              itemBuilder: (context, index) => _NotificationTile(
                item: visible[index],
                onDelete: () => _delete(visible[index]),
              ),
            );
          }(),
          AsyncValue(:final error?) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item, required this.onDelete});

  final CommunityNotification item;
  final VoidCallback onDelete;

  String _text(AppLocalizations l10n, String name) => switch (item.type) {
    NotificationType.like => l10n.notificationLike(name),
    NotificationType.comment => l10n.notificationComment(name),
    NotificationType.reply => l10n.notificationReply(name),
    NotificationType.follow => l10n.notificationFollow(name),
    NotificationType.learn => l10n.notificationLearn(name),
  };

  IconData get _icon => switch (item.type) {
    NotificationType.like => Icons.favorite_rounded,
    NotificationType.comment => Icons.chat_bubble_rounded,
    NotificationType.reply => Icons.reply_rounded,
    NotificationType.follow => Icons.person_add_alt_1_rounded,
    NotificationType.learn => Icons.school_rounded,
  };

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).value;
    if (uid != null && !item.read) {
      ref.read(socialRepositoryProvider).markRead(uid, [item.id]).ignore();
    }
    final postId = item.postId;
    await context.push(
      postId != null &&
              item.type != NotificationType.follow &&
              item.type != NotificationType.learn
          ? AppRoutes.post(postId)
          : AppRoutes.member(item.actorId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actor = ref.watch(userProfileProvider(item.actorId)).value;
    final name = actor?.name ?? l10n.memberFallbackName;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.deleteNotificationAction): onDelete,
      },
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          color: AppColors.surface2,
          child: const Icon(Icons.delete_outline_rounded),
        ),
        onDismissed: (_) => onDelete(),
        child: ListTile(
          minTileHeight: 72,
          tileColor: item.read ? null : AppColors.neon.withValues(alpha: 0.06),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(name: name, photo: actor?.photo, size: 46),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 15, color: AppColors.neon),
                ),
              ),
            ],
          ),
          title: Text(_text(l10n, name)),
          subtitle: Text(
            [
              relativeTime(context, item.createdAt),
              if (!item.read) l10n.unreadLabel,
            ].join(' · '),
          ),
          onTap: () => _open(context, ref),
        ),
      ),
    );
  }
}
