import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../matches/matches.dart';
import '../../profile/profile.dart';
import '../../profile/skills.dart';
import '../community_providers.dart';
import '../learn_request.dart';
import '../models.dart';
import 'community_widgets.dart';
import 'post_actions.dart';
import 'post_video_player.dart';
import '../../../core/utils/person_name.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    required this.post,
    this.detailed = false,
    this.onRemoved,
    this.onComment,
    super.key,
  });

  final CommunityPost post;

  final bool detailed;

  final VoidCallback? onRemoved;

  final VoidCallback? onComment;

  void _open(BuildContext context) {
    if (!detailed) context.push(AppRoutes.post(post.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final time = relativeTime(context, post.createdAt);
    return CommunityCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthorHeader(
            authorId: post.authorId,
            subtitle: post.isEdited ? '$time · ${l10n.postEdited}' : time,
            trailing: IconButton(
              tooltip: l10n.postMenuTooltip,
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: () =>
                  showPostMenu(context, ref, post: post, onRemoved: onRemoved),
            ),
          ),
          if (post.video != null) ...[
            const SizedBox(height: AppSpacing.md),
            PostVideoPlayer(post: post),
          ] else if (post.mediaCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            PostMediaCarousel(post: post, onTap: () => _open(context)),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostTypeBadge(type: post.type),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Description(
                    text: post.description,
                    expanded: detailed,
                    onMore: () => _open(context),
                  ),
                ],
                if (post.tags.isNotEmpty || post.skillIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final skill in post.skillIds)
                        SkillTag(label: Skills.label(l10n, skill)),
                      for (final tag in post.tags)
                        HashtagChip(
                          tag: tag,
                          onTap: () => context.push(
                            AppRoutes.communitySearchFor('#$tag'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          LearnPanel(authorId: post.authorId, post: post),
          const SizedBox(height: AppSpacing.sm),
          _ActionsRow(
            post: post,
            onComment: detailed ? onComment : () => _open(context),
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({
    required this.text,
    required this.expanded,
    required this.onMore,
  });

  final String text;
  final bool expanded;
  final VoidCallback onMore;

  static const int _collapsedLines = 4;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.white,
      fontSize: 15.5,
      height: 1.4,
    );
    if (expanded) return SelectableText(text, style: style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: _collapsedLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 40),
                  foregroundColor: AppColors.neon,
                ),
                onPressed: onMore,
                child: Text(context.l10n.readMore),
              ),
          ],
        );
      },
    );
  }
}

class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({required this.post, this.onTap, super.key});

  final CommunityPost post;
  final VoidCallback? onTap;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final count = post.mediaCount;
    final l10n = context.l10n;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: post.aspectRatios.first,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Semantics(
                    image: true,
                    label: l10n.postImageSemantics(index + 1, count),
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: PostImageView(
                        postId: post.id,
                        index: index,
                        placeholder: index == 0 ? post.thumb : null,
                      ),
                    ),
                  ),
                ),
                if (count > 1)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${_page + 1}/$count',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: AppMotion.of(context, AppMotion.short),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.neon : AppColors.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PostImageView extends ConsumerWidget {
  const PostImageView({
    required this.postId,
    required this.index,
    this.placeholder,
    super.key,
  });

  final String postId;
  final int index;
  final Uint8List? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (postId: postId, index: index);
    final media = ref.watch(postMediaProvider(key));
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixels =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(1, 2048);
        final thumb = placeholder;
        final loading = Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surface3),
            if (thumb != null)
              Image.memory(
                thumb,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            const Center(
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ],
        );
        return switch (media) {
          AsyncData(:final value) => Image.memory(
            value.bytes,
            fit: BoxFit.cover,
            cacheWidth: pixels,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _BrokenImage(
              onRetry: () => ref.invalidate(postMediaProvider(key)),
            ),
          ),
          AsyncError() => _BrokenImage(
            onRetry: () => ref.invalidate(postMediaProvider(key)),
          ),
          _ => loading,
        };
      },
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.surface3,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.broken_image_outlined),
          label: Text(l10n.imageLoadFailed),
        ),
      ),
    );
  }
}

class LearnPanel extends ConsumerWidget {
  const LearnPanel({required this.authorId, this.post, super.key});

  final String authorId;

  final CommunityPost? post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final author = ref.watch(userProfileProvider(authorId)).value;
    final me = ref.watch(authStateProvider).value;
    if (author == null || me == null || me == authorId) {
      return const SizedBox.shrink();
    }
    final skills = post == null
        ? author.teach
        : teachableSkills(author, post!.skillIds);
    if (skills.isEmpty) return const SizedBox.shrink();
    final status = ref.watch(learnStatusProvider(authorId)).value;
    if (status == null || status is LearnSelf || status is LearnUnavailable) {
      return const SizedBox.shrink();
    }
    final firstName = PersonName.first(author.name);
    final skillNames = skills.take(2).map((s) => Skills.label(l10n, s));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.neon.withValues(alpha: 0.7)),
              color: AppColors.neon.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  color: AppColors.neon,
                  size: 30,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.learnPanelTitle,
                        style: const TextStyle(
                          color: AppColors.neon,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.learnPanelBody(firstName, skillNames.join(', ')),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (status) {
            LearnMatched(:final matchId) => _NeonButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: l10n.openChatAction,
              onPressed: () => context.push(AppRoutes.chat(matchId)),
            ),
            LearnPending() => _PendingChip(label: l10n.learnPending),
            _ => _NeonButton(
              icon: Icons.handshake_outlined,
              label: l10n.learnWithAction(firstName),
              onPressed: () =>
                  startLearnRequest(context, ref, author: author, post: post),
            ),
          },
        ],
      ),
    );
  }
}

Future<void> startLearnRequest(
  BuildContext context,
  WidgetRef ref, {
  required UserProfile author,
  CommunityPost? post,
}) async {
  final l10n = context.l10n;
  final firstName = PersonName.first(author.name);
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
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
            l10n.learnConfirmTitle(firstName),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.learnConfirmBody(firstName),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: l10n.learnConfirmAction,
            icon: Icons.handshake_outlined,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final bool matched;
  try {
    matched = await sendLearnRequest(ref, author: author, postId: post?.id);
  } catch (error) {
    if (context.mounted) showAppSnackBar(context, l10n.failureMessage(error));
    return;
  }
  if (!context.mounted) return;
  unawaited(HapticFeedback.mediumImpact());
  if (!matched) {
    showAppSnackBar(context, l10n.learnSent(firstName));
    return;
  }
  final me = ref.read(authStateProvider).value;
  if (me == null) return;
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.handshake_outlined,
        size: 40,
        color: AppColors.neon,
      ),
      title: Text(l10n.matchDialogTitle, textAlign: TextAlign.center),
      content: Text(
        l10n.matchDialogBody(author.name),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.keepExploringAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.openChatAction),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) {
    await context.push(AppRoutes.chat(Match.pairId(me, author.id)));
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.black,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, maxLines: 2, textAlign: TextAlign.center),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.neon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow({required this.post, required this.onComment});

  final CommunityPost post;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final comments = ref.watch(commentCountProvider(post.id)).value;
    final saved = ref.watch(savedProvider(post.id)).value ?? false;
    return Row(
      children: [
        LikeButton(post: post),
        _CountButton(
          icon: Icons.chat_bubble_outline_rounded,
          count: comments,
          tooltip: l10n.commentAction,
          semantics: comments == null ? null : l10n.commentsCount(comments),
          onPressed: onComment,
        ),
        IconButton(
          tooltip: l10n.shareAction,
          icon: const Icon(Icons.send_outlined),
          onPressed: () => showShareSheet(context, post: post),
        ),
        const Spacer(),
        IconButton(
          tooltip: saved ? l10n.unsaveAction : l10n.saveAction,
          isSelected: saved,
          selectedIcon: const Icon(
            Icons.bookmark_rounded,
            color: AppColors.neon,
          ),
          icon: const Icon(Icons.bookmark_border_rounded),
          onPressed: () => toggleSaved(context, ref, post.id, saved: !saved),
        ),
      ],
    );
  }
}

Future<void> toggleSaved(
  BuildContext context,
  WidgetRef ref,
  String postId, {
  required bool saved,
}) async {
  final uid = ref.read(authStateProvider).value;
  if (uid == null) return;
  final l10n = context.l10n;
  try {
    await ref
        .read(socialRepositoryProvider)
        .setSaved(uid: uid, postId: postId, saved: saved);
    if (context.mounted) {
      showAppSnackBar(context, saved ? l10n.postSaved : l10n.postUnsaved);
    }
  } catch (error) {
    if (context.mounted) showAppSnackBar(context, l10n.failureMessage(error));
  }
}

class LikeButton extends ConsumerWidget {
  const LikeButton({required this.post, super.key});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final like = ref.watch(likeControllerProvider(post.id)).value;
    final liked = like?.liked ?? false;
    return _CountButton(
      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: liked ? AppColors.heart : null,
      count: like?.count,
      tooltip: liked ? l10n.unlikeAction : l10n.likePostAction,
      semantics: like == null ? null : l10n.likesCount(like.count),
      selected: liked,
      onPressed: like == null
          ? null
          : () async {
              unawaited(HapticFeedback.selectionClick());
              try {
                await ref
                    .read(likeControllerProvider(post.id).notifier)
                    .toggle(authorId: post.authorId);
              } catch (error) {
                if (context.mounted) {
                  showAppSnackBar(context, l10n.failureMessage(error));
                }
              }
            },
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
    this.semantics,
    this.color,
    this.selected = false,
  });

  final IconData icon;
  final int? count;
  final String tooltip;
  final String? semantics;
  final VoidCallback? onPressed;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    return Semantics(
      button: true,
      selected: selected,
      label: [tooltip, ?semantics].join(', '),
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: child,
                    ),
                    child: Icon(
                      icon,
                      key: ValueKey(icon),
                      color: color ?? AppColors.white,
                      size: 26,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      NumberFormat.compact(
                        locale: Localizations.localeOf(context).toLanguageTag(),
                      ).format(count),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
