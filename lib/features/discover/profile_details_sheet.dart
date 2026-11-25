import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/glass.dart';
import '../profile/profile.dart';
import '../profile/skills.dart';
import 'knowledge_match.dart';

Future<bool> showProfileDetailsSheet(
  BuildContext context, {
  required UserProfile me,
  required UserProfile profile,
}) async {
  final report = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface1,
    builder: (_) => _ProfileDetails(me: me, profile: profile),
  );
  return report ?? false;
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.me, required this.profile});

  final UserProfile me;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final match = KnowledgeMatch.between(me, profile);
    final score = Compatibility.score(me, profile);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              ProfileAvatar(name: profile.name, photo: profile.photo, size: 72),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: textTheme.headlineSmall),
                    if (score > 0)
                      Text(
                        '${l10n.compatibilityLabel}: $score%',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.neon,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              profile.bio,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          _Skills(
            title: l10n.teachesLabel,
            ids: profile.teach,
            highlight: match?.iCanLearn.toSet() ?? const {},
          ),
          _Skills(
            title: l10n.wantsLabel,
            ids: profile.learn,
            highlight: match?.iCanTeach.toSet() ?? const {},
          ),
          const SizedBox(height: AppSpacing.xxxl),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.reportProfileTooltip),
          ),
        ],
      ),
    );
  }
}

class _Skills extends StatelessWidget {
  const _Skills({
    required this.title,
    required this.ids,
    required this.highlight,
  });

  final String title;
  final List<String> ids;
  final Set<String> highlight;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final id in ids)
                GlassChip(
                  label: Skills.label(l10n, id),
                  highlighted: highlight.contains(id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
