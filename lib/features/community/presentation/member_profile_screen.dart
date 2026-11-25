import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile.dart';
import '../../profile/skills.dart';
import '../../safety/safety_ui.dart';
import '../community_providers.dart';
import '../community_repository.dart';
import '../learn_request.dart';
import '../models.dart';
import 'community_widgets.dart';
import 'post_actions.dart';
import 'post_card.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({required this.uid, super.key});

  final String uid;

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    final action = await showActionSheet<String>(
      context,
      actions: (context) => [
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.reportMemberAction),
          onTap: () => Navigator.of(context).pop('report'),
        ),
        ListTile(
          leading: Icon(
            Icons.block_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.blockMemberAction(profile.name)),
          onTap: () => Navigator.of(context).pop('block'),
        ),
      ],
    );
    if (!context.mounted) return;
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    if (action == 'block') {
      await blockMember(
        context,
        ref,
        otherId: profile.id,
        otherName: profile.name,
      );
    } else if (action == 'report') {
      final match = await findMatch(
        ProviderScope.containerOf(context, listen: false),
        me,
        profile.id,
      );
      if (!context.mounted) return;
      final sent = await showReportSheet(
        context,
        me: me,
        otherId: profile.id,
        otherName: profile.name,
        match: match,
      );
      if (sent && context.mounted) showAppSnackBar(context, l10n.reportDone);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider(uid));
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    final isMe = me == uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.value?.name ?? ''),
        actions: [
          if (!isMe && profile.value != null)
            IconButton(
              tooltip: l10n.memberMenuTooltip,
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => _menu(context, ref, profile.value!),
            ),
        ],
      ),
      body: ContentWidth(
        child: switch (profile) {
          AsyncData(:final value?) when blocked.contains(uid) => MessageView(
            icon: Icons.block_rounded,
            title: l10n.memberBlockedTitle(value.name),
            body: l10n.memberBlockedBody,
          ),
          AsyncData(:final value?) => _ProfileBody(profile: value, isMe: isMe),
          AsyncData() => MessageView(
            icon: Icons.person_off_outlined,
            title: l10n.memberNotFound,
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(userProfileProvider(uid)),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile, required this.isMe});

  final UserProfile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = PostQuery.author(profile.id);
    return RefreshIndicator(
      color: AppColors.neon,
      onRefresh: () async {
        ref
          ..invalidate(memberStatsProvider(profile.id))
          ..invalidate(postListProvider(query))
          ..invalidate(learnStatusProvider(profile.id));
        await ref.read(postListProvider(query).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    RingAvatar(
                      name: profile.name,
                      photo: profile.photo,
                      size: 92,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: MemberStatsRow(uid: profile.id)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (profile.teach.isNotEmpty)
                  Text(
                    l10n.teachesSkill(
                      profile.teach
                          .take(3)
                          .map((s) => Skills.label(l10n, s))
                          .join(' • '),
                    ),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(profile.bio, style: const TextStyle(height: 1.4)),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (isMe)
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.editProfile),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.editProfileAction),
                  )
                else
                  _ActionButtons(profile: profile),
                LearnPanel(authorId: profile.id),
                const SizedBox(height: AppSpacing.xl),
                _SkillsBlock(title: l10n.teachSectionTitle, ids: profile.teach),
                const SizedBox(height: AppSpacing.md),
                _SkillsBlock(title: l10n.learnSectionTitle, ids: profile.learn),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.neon,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.portfolioTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PostGridSliver(
            query: query,
            emptyText: isMe ? l10n.portfolioEmptyMine : l10n.portfolioEmpty,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }
}

class MemberStatsRow extends ConsumerWidget {
  const MemberStatsRow({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(memberStatsProvider(uid)).value;
    Widget stat(int? value, String label, VoidCallback? onTap) => Expanded(
      child: Semantics(
        button: onTap != null,
        label: '${value ?? '–'} $label',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value == null ? '–' : '$value',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        stat(stats?.posts, l10n.statPosts, null),
        stat(
          stats?.followers,
          l10n.statFollowers,
          () => context.push(AppRoutes.followers(uid)),
        ),
        stat(
          stats?.following,
          l10n.statFollowing,
          () => context.push(AppRoutes.following(uid)),
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerStatefulWidget {
  const _ActionButtons({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _busy = false;

  Future<void> _toggleFollow(bool following) async {
    final me = ref.read(authStateProvider).value;
    if (me == null || _busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final social = ref.read(socialRepositoryProvider);
    try {
      following
          ? await social.unfollow(me, widget.profile.id)
          : await social.follow(me, widget.profile.id);
      if (!mounted) return;
      ref
        ..invalidate(memberStatsProvider(widget.profile.id))
        ..invalidate(memberStatsProvider(me));
    } catch (error) {
      if (mounted) showAppSnackBar(context, l10n.failureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final following =
        ref.watch(isFollowingProvider(widget.profile.id)).value ?? false;
    final status = ref.watch(learnStatusProvider(widget.profile.id)).value;
    final followButton = following
        ? OutlinedButton.icon(
            onPressed: _busy ? null : () => _toggleFollow(true),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.followingAction),
          )
        : FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neon,
              foregroundColor: AppColors.black,
            ),
            onPressed: _busy ? null : () => _toggleFollow(false),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.followAction),
          );
    final matchId = switch (status) {
      LearnMatched(:final matchId) => matchId,
      _ => null,
    };
    return AdaptiveButtonRow(
      labels: [
        following ? l10n.followingAction : l10n.followAction,
        if (matchId != null) l10n.messageAction,
      ],
      children: [
        followButton,
        if (matchId != null)
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.chat(matchId)),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(l10n.messageAction),
          ),
      ],
    );
  }
}

class _SkillsBlock extends StatelessWidget {
  const _SkillsBlock({required this.title, required this.ids});

  final String title;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final id in ids) SkillTag(label: Skills.label(l10n, id)),
          ],
        ),
      ],
    );
  }
}

class PostGridSliver extends ConsumerWidget {
  const PostGridSliver({
    required this.query,
    required this.emptyText,
    super.key,
  });

  final PostQuery query;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(postListProvider(query));
    return switch (list) {
      AsyncValue(:final value?) when value.posts.isEmpty => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
      AsyncValue(:final value?) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: value.posts.length,
          itemBuilder: (context, index) {
            if (index >= value.posts.length - 3 &&
                value.hasMore &&
                !value.isLoadingMore &&
                !value.loadMoreFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ref.read(postListProvider(query).notifier).loadMore();
                }
              });
            }
            return PostGridTile(post: value.posts[index]);
          },
        ),
      ),
      AsyncValue(:final error?) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(l10n.failureMessage(error), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.invalidate(postListProvider(query)),
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
      ),
      _ => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

class PostGridTile extends StatelessWidget {
  const PostGridTile({required this.post, super.key});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thumb = post.thumb;
    return Semantics(
      button: true,
      label: [
        if (post.video != null) l10n.videoLabel,
        l10n.openPostSemantics(
          post.description.isEmpty ? post.type.label(l10n) : post.description,
        ),
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(AppRoutes.post(post.id)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.memory(
                  thumb,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.surface3),
                )
              else
                Container(
                  color: AppColors.surface2,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    post.description,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              if (post.video != null)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 20,
                    color: AppColors.white,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                )
              else if (post.mediaCount > 1)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.collections_rounded,
                    size: 18,
                    color: AppColors.white,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({
    required this.uid,
    required this.followers,
    super.key,
  });

  final String uid;
  final bool followers;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final List<String> _ids = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(socialRepositoryProvider)
          .fetchFollows(
            widget.uid,
            followers: widget.followers,
            cursor: _cursor,
          );
      if (!mounted) return;
      setState(() {
        _ids.addAll(page.ids.where((id) => !_ids.contains(id)));
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
    final ids = _ids.where((id) => !blocked.contains(id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.followers ? l10n.statFollowers : l10n.statFollowing),
      ),
      body: ContentWidth(
        child: _error != null && _ids.isEmpty
            ? ErrorView(error: _error!, onRetry: _loadMore)
            : ids.isEmpty && !_loading
            ? MessageView(
                icon: Icons.people_outline_rounded,
                title: widget.followers
                    ? l10n.followersEmpty
                    : l10n.followingEmpty,
              )
            : ListView.builder(
                itemCount: ids.length + 1,
                itemBuilder: (context, index) {
                  if (index == ids.length) {
                    if (_loading) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _hasMore
                        ? TextButton(
                            onPressed: _loadMore,
                            child: Text(l10n.loadMoreAction),
                          )
                        : const SizedBox(height: AppSpacing.xl);
                  }
                  return MemberTile(uid: ids[index]);
                },
              ),
      ),
    );
  }
}

class MemberTile extends ConsumerWidget {
  const MemberTile({required this.uid, this.preloaded, super.key});

  final String uid;

  final UserProfile? preloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = preloaded ?? ref.watch(userProfileProvider(uid)).value;
    final name = profile?.name ?? l10n.memberFallbackName;
    final skill = profile?.teach.firstOrNull;
    return ListTile(
      minTileHeight: 64,
      leading: RingAvatar(name: name, photo: profile?.photo, size: 46),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: skill == null
          ? null
          : Text(
              l10n.teachesSkill(Skills.label(l10n, skill)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => context.push(AppRoutes.member(uid)),
    );
  }
}
