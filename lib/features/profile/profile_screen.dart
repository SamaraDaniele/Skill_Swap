import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/person_name.dart';
import '../../core/widgets/app_widgets.dart';
import '../auth/auth_repository.dart';
import '../community/presentation/member_profile_screen.dart';
import 'profile.dart';
import 'skills.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
        actions: [
          IconButton(
            tooltip: l10n.signOutAction,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: ContentWidth(
        child: switch (profile) {
          AsyncData(:final value?) => ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              _ProfileHeader(profile: value),
              if (value.bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  value.bio,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              MemberStatsRow(uid: value.id),
              const SizedBox(height: AppSpacing.md),
              AdaptiveButtonRow(
                labels: [l10n.myPortfolioAction, l10n.savedTitle],
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.member(value.id)),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: Text(l10n.myPortfolioAction),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.saved),
                    icon: const Icon(Icons.bookmark_border_rounded),
                    label: Text(l10n.savedTitle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _SkillSection(title: l10n.teachSectionTitle, ids: value.teach),
              const SizedBox(height: AppSpacing.xxl),
              _SkillSection(title: l10n.learnSectionTitle, ids: value.learn),
              const SizedBox(height: AppSpacing.huge),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.editProfile),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.editProfileAction),
              ),
            ],
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({required this.title, required this.ids});

  final String title;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.md),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  static const double _avatar = 72;

  static double _longestWord(
    BuildContext context,
    String name,
    TextStyle? style,
  ) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    try {
      var widest = 0.0;
      for (final word in PersonName.words(name)) {
        painter
          ..text = TextSpan(
            text: word,
            style: DefaultTextStyle.of(context).style.merge(style),
          )
          ..layout();
        widest = math.max(widest, painter.width);
      }
      return widest;
    } finally {
      painter.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    final avatar = ProfileAvatar(
      name: profile.name,
      photo: profile.photo,
      size: _avatar,
    );
    final name = Text(profile.name, style: style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final nameWidth = constraints.maxWidth - _avatar - AppSpacing.lg;
        if (_longestWord(context, profile.name, style) <= nameWidth) {
          return Row(
            children: [
              avatar,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: name),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(height: AppSpacing.md),
            name,
          ],
        );
      },
    );
  }
}
