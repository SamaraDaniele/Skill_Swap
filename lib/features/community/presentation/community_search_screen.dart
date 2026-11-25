import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/error/failure.dart';
import '../../../core/firebase_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/auth_repository.dart';
import '../../profile/profile.dart';
import '../../profile/skills.dart';
import '../community_providers.dart';
import '../community_repository.dart';
import '../models.dart';
import 'community_screen.dart';
import 'member_profile_screen.dart';

final memberSearchProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, term) async {
      final trimmed = term.trim();
      if (trimmed.length < 2) return const [];
      final variants = {
        trimmed,
        trimmed
            .split(RegExp(r'\s+'))
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(' '),
      };
      final users = ref.read(firestoreProvider).collection(Collections.users);
      final snaps = await guard(
        () => Future.wait([
          for (final v in variants)
            users.orderBy('name').startAt([v]).endAt(['$v']).limit(20).get(),
        ]),
      );
      final seen = <String>{};
      return [
        for (final snap in snaps)
          for (final doc in snap.docs)
            if (seen.add(doc.id)) UserProfile.fromMap(doc.id, doc.data()),
      ];
    }, retry: communityRetry);

final skillTeachersProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, skillId) async {
      final snap = await guard(
        () => ref
            .read(firestoreProvider)
            .collection(Collections.users)
            .where('teach', arrayContains: skillId)
            .limit(20)
            .get(),
      );
      return snap.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList();
    }, retry: communityRetry);

enum _SearchTab { people, posts, skills }

class CommunitySearchScreen extends ConsumerStatefulWidget {
  const CommunitySearchScreen({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  ConsumerState<CommunitySearchScreen> createState() =>
      _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  late String _term = widget.initialQuery;
  late _SearchTab _tab = widget.initialQuery.startsWith('#')
      ? _SearchTab.posts
      : _SearchTab.people;
  String? _skill;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _term = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (value) => setState(() => _term = value.trim()),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            border: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: SegmentedButton<_SearchTab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _SearchTab.people,
                    label: Text(l10n.searchPeople),
                  ),
                  ButtonSegment(
                    value: _SearchTab.posts,
                    label: Text(l10n.searchPosts),
                  ),
                  ButtonSegment(
                    value: _SearchTab.skills,
                    label: Text(l10n.searchSkills),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                _SearchTab.people => _PeopleResults(term: _term),
                _SearchTab.posts => _PostResults(term: _term),
                _SearchTab.skills => _SkillResults(
                  selected: _skill,
                  onSelected: (id) => setState(() => _skill = id),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleResults extends ConsumerWidget {
  const _PeopleResults({required this.term});

  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (term.length < 2) {
      return MessageView(
        icon: Icons.person_search_outlined,
        title: l10n.searchPeopleHint,
      );
    }
    final me = ref.watch(authStateProvider).value;
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    return switch (ref.watch(memberSearchProvider(term))) {
      AsyncData(:final value) => () {
        final people = value
            .where((p) => p.id != me && !blocked.contains(p.id))
            .toList();
        if (people.isEmpty) {
          return MessageView(
            icon: Icons.search_off_rounded,
            title: l10n.searchNoPeople(term),
            body: l10n.searchPeopleLimit,
          );
        }
        return ListView(
          children: [
            for (final p in people) MemberTile(uid: p.id, preloaded: p),
          ],
        );
      }(),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(memberSearchProvider(term)),
      ),
      _ => const LoadingView(),
    };
  }
}

class _PostResults extends StatelessWidget {
  const _PostResults({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keyword = CommunityText.searchKeyword(term);
    if (keyword == null) {
      return MessageView(
        icon: Icons.manage_search_rounded,
        title: l10n.searchPostsHint,
      );
    }
    return CustomScrollView(
      slivers: [
        PostSliverList(
          query: PostQuery.keyword(keyword),
          empty: MessageView(
            icon: Icons.search_off_rounded,
            title: l10n.searchNoPosts(keyword),
            body: l10n.searchPostsLimit,
          ),
        ),
      ],
    );
  }
}

class _SkillResults extends ConsumerWidget {
  const _SkillResults({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final skill = selected;
    final skills = [...Skills.all]
      ..sort((a, b) => Skills.label(l10n, a).compareTo(Skills.label(l10n, b)));
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final id in skills)
                  ChoiceChip(
                    label: Text(Skills.label(l10n, id)),
                    selected: id == skill,
                    onSelected: (on) => onSelected(on ? id : null),
                  ),
              ],
            ),
          ),
        ),
        if (skill == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: MessageView(
              icon: Icons.layers_outlined,
              title: l10n.searchSkillsHint,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.skillTeachersTitle(Skills.label(l10n, skill)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _Teachers(skillId: skill),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.skillPostsTitle(Skills.label(l10n, skill)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          PostSliverList(
            query: PostQuery.skill(skill),
            empty: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(
                l10n.skillPostsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Teachers extends ConsumerWidget {
  const _Teachers({required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authStateProvider).value;
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    return switch (ref.watch(skillTeachersProvider(skillId))) {
      AsyncData(:final value) => () {
        final people = value
            .where((p) => p.id != me && !blocked.contains(p.id))
            .toList();
        if (people.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.skillTeachersEmpty,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return SliverList.list(
          children: [
            for (final p in people) MemberTile(uid: p.id, preloaded: p),
          ],
        );
      }(),
      AsyncError(:final error) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(l10n.failureMessage(error)),
        ),
      ),
      _ => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}
