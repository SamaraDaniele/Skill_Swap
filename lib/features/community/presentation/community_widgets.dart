import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../profile/profile.dart';
import '../../profile/skills.dart';
import '../models.dart';

String relativeTime(BuildContext context, DateTime time, {DateTime? now}) {
  final l10n = context.l10n;
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inHours < 1) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
      .format(time);
}

extension PostTypeLabel on PostType {
  String label(AppLocalizations l10n) => switch (this) {
    PostType.project => l10n.postTypeProject,
    PostType.tip => l10n.postTypeTip,
    PostType.knowledge => l10n.postTypeKnowledge,
    PostType.question => l10n.postTypeQuestion,
    PostType.achievement => l10n.postTypeAchievement,
    PostType.work => l10n.postTypeWork,
  };

  IconData get icon => switch (this) {
    PostType.project => Icons.rocket_launch_outlined,
    PostType.tip => Icons.lightbulb_outline_rounded,
    PostType.knowledge => Icons.school_outlined,
    PostType.question => Icons.help_outline_rounded,
    PostType.achievement => Icons.emoji_events_outlined,
    PostType.work => Icons.work_outline_rounded,
  };
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badgeCount;

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.black : AppColors.white;
    return Semantics(
      button: true,
      label: badgeCount > 0
          ? '$tooltip, ${context.l10n.unreadBadge(badgeCount)}'
          : tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 26,
          child: SizedBox.square(
            dimension: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.neon : AppColors.graphite,
                    border: filled
                        ? null
                        : Border.all(color: AppColors.outlineSoft),
                    boxShadow: filled
                        ? const [
                            BoxShadow(
                              color: AppColors.neonGlow,
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: fg, size: 24),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.neon,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HashtagChip extends StatelessWidget {
  const HashtagChip({required this.tag, this.onTap, super.key});

  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: context.l10n.hashtagSemantics(tag),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.8)),
            ),
            child: Text(
              '#$tag',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.neon,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PostTypeBadge extends StatelessWidget {
  const PostTypeBadge({required this.type, super.key});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 13, color: AppColors.violetLight),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              type.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.violetLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RingAvatar extends StatelessWidget {
  const RingAvatar({required this.name, this.photo, this.size = 48, super.key});

  final String name;
  final Uint8List? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neon,
      ),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.black,
        ),
        child: ProfileAvatar(name: name, photo: photo, size: size - 7),
      ),
    );
  }
}

class AuthorHeader extends ConsumerWidget {
  const AuthorHeader({
    required this.authorId,
    this.trailing,
    this.subtitle,
    this.avatarSize = 48,
    super.key,
  });

  final String authorId;
  final Widget? trailing;

  final String? subtitle;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider(authorId)).value;
    final name = profile?.name ?? l10n.memberFallbackName;
    final skill = profile?.teach.firstOrNull;
    final line = [
      if (skill != null) l10n.teachesSkill(Skills.label(l10n, skill)),
      ?subtitle,
    ].join(' · ');
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: l10n.openMemberProfile(name),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => context.push(AppRoutes.member(authorId)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    RingAvatar(
                      name: name,
                      photo: profile?.photo,
                      size: avatarSize,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (line.isNotEmpty)
                              Text(
                                line,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: child,
    );
  }
}

class CommunityMessage extends StatelessWidget {
  const CommunityMessage({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: icon,
    title: title,
    body: body,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
