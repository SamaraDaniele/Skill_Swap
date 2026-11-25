import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../profile/profile.dart';
import '../profile/skills.dart';
import 'knowledge_match.dart';
import '../../core/utils/person_name.dart';

class KnowledgeBanner extends StatelessWidget {
  const KnowledgeBanner({required this.match, required this.other, super.key});

  final KnowledgeMatch match;
  final UserProfile other;

  String _skills(AppLocalizations l10n, List<String> ids) {
    final labels = ids.take(2).map((id) => Skills.label(l10n, id)).toList();
    return labels.length == 1
        ? labels.single
        : l10n.skillPair(labels[0], labels[1]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final firstName = PersonName.first(other.name);
    final body = switch (match.type) {
      KnowledgeMatchType.exchange => l10n.knowledgeExchange(
        _skills(l10n, match.iCanTeach),
        _skills(l10n, match.iCanLearn),
        firstName,
      ),
      KnowledgeMatchType.teach => l10n.knowledgeTeach(
        _skills(l10n, match.iCanTeach),
        firstName,
      ),
      KnowledgeMatchType.learn => l10n.knowledgeLearn(
        firstName,
        _skills(l10n, match.iCanLearn),
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 7, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.inkBanner.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neon, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.neon.withValues(alpha: 0.32),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: -math.pi / 4,
            child: const Icon(
              Icons.link_rounded,
              color: AppColors.neon,
              size: 34,
              shadows: [Shadow(color: AppColors.neonGlow, blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.knowledgeMatchTitle,
                  style: const TextStyle(
                    color: AppColors.neon,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
