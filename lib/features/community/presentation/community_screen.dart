import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/line_icons.dart';
import '../community_providers.dart';
import '../community_repository.dart';
import 'community_widgets.dart';
import 'post_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  FeedTab _tab = FeedTab.forYou;

  Future<void> _refresh() async {
    ref.invalidate(feedQueryProvider(_tab));
    final query = await ref.read(feedQueryProvider(_tab).future);
    ref
      ..invalidate(postListProvider(query))
      ..invalidate(likeControllerProvider)
      ..invalidate(commentCountProvider);
    await ref.read(postListProvider(query).future);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(feedQueryProvider(_tab));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: RefreshIndicator(
            color: AppColors.neon,
            onRefresh: _refresh,
            child: CustomScrollView(
              key: PageStorageKey('community-${_tab.name}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(
                  child: _FilterChips(
                    selected: _tab,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                ),
                switch (query) {
                  AsyncValue(:final value?) => PostSliverList(
                    query: value,
                    empty: _emptyFor(context, _tab),
                  ),
                  AsyncValue(:final error?) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(feedQueryProvider(_tab)),
                    ),
                  ),
                  _ => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(),
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyFor(BuildContext context, FeedTab tab) {
    final l10n = context.l10n;
    return switch (tab) {
      FeedTab.forYou => CommunityMessage(
        icon: Icons.dynamic_feed_outlined,
        title: l10n.feedEmptyTitle,
        body: l10n.feedEmptyBody,
        actionLabel: l10n.newPostAction,
        onAction: () => context.push(AppRoutes.newPost),
      ),
      FeedTab.following => CommunityMessage(
        icon: Icons.group_add_outlined,
        title: l10n.feedFollowingEmptyTitle,
        body: l10n.feedFollowingEmptyBody,
        actionLabel: l10n.searchPeopleAction,
        onAction: () => context.push(AppRoutes.communitySearch),
      ),
      FeedTab.skills => CommunityMessage(
        icon: Icons.layers_outlined,
        title: l10n.feedSkillsEmptyTitle,
        body: l10n.feedSkillsEmptyBody,
      ),
      FeedTab.projects => CommunityMessage(
        icon: Icons.rocket_launch_outlined,
        title: l10n.feedProjectsEmptyTitle,
        body: l10n.feedProjectsEmptyBody,
        actionLabel: l10n.newPostAction,
        onAction: () => context.push(AppRoutes.newPost),
      ),
    };
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LineIcon(
                LineIconShape.people,
                size: 34,
                color: AppColors.neon,
                glow: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.communityTitle,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              RoundIconButton(
                icon: Icons.search_rounded,
                tooltip: l10n.searchAction,
                onPressed: () => context.push(AppRoutes.communitySearch),
              ),
              RoundIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: l10n.notificationsTitle,
                badgeCount: unread,
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              RoundIconButton(
                icon: Icons.add_rounded,
                tooltip: l10n.newPostAction,
                filled: true,
                onPressed: () => context.push(AppRoutes.newPost),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.communitySubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final FeedTab selected;
  final ValueChanged<FeedTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(FeedTab tab) => switch (tab) {
      FeedTab.forYou => l10n.feedForYou,
      FeedTab.following => l10n.feedFollowing,
      FeedTab.skills => l10n.feedSkills,
      FeedTab.projects => l10n.feedProjects,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final tab in FeedTab.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(label(tab)),
                selected: tab == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(tab),
                labelStyle: TextStyle(
                  color: tab == selected ? AppColors.black : AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: AppColors.neon,
                backgroundColor: AppColors.graphite,
                side: BorderSide(
                  color: tab == selected
                      ? AppColors.neon
                      : AppColors.outlineSoft,
                ),
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
        ],
      ),
    );
  }
}

class PostSliverList extends ConsumerWidget {
  const PostSliverList({required this.query, required this.empty, super.key});

  final PostQuery query;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(postListProvider(query));
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    return switch (list) {
      AsyncValue(:final value?) => () {
        final notifier = ref.read(postListProvider(query).notifier);
        final canLoadMore =
            value.hasMore && !value.isLoadingMore && !value.loadMoreFailed;
        void loadMoreSoon() =>
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) notifier.loadMore();
            });
        final posts = value.posts
            .where((p) => !blocked.contains(p.authorId))
            .toList();
        if (posts.isEmpty && !value.hasMore) {
          return SliverFillRemaining(hasScrollBody: false, child: empty);
        }
        if (posts.isEmpty && canLoadMore) loadMoreSoon();
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          sliver: SliverList.builder(
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return _Footer(state: value, onLoadMore: notifier.loadMore);
              }
              if (index >= posts.length - 3 && canLoadMore) loadMoreSoon();
              final post = posts[index];
              return Padding(
                key: ValueKey(post.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: PostCard(
                  post: post,
                  onRemoved: () => ref
                      .read(postListProvider(query).notifier)
                      .remove(post.id),
                ),
              );
            },
          ),
        );
      }(),
      AsyncValue(:final error?) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(postListProvider(query)),
        ),
      ),
      _ => SliverFillRemaining(
        hasScrollBody: false,
        child: Semantics(label: l10n.loadingPosts, child: const LoadingView()),
      ),
    };
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onLoadMore});

  final PostListState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.loadMoreFailed),
          ),
        ),
      );
    }
    if (!state.hasMore && state.posts.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          l10n.feedEnd,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.xxl);
  }
}
