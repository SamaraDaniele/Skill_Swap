import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_tokens.dart';
import 'match_card.dart' show kDeckCardRadius;

class DeckBackCard extends StatelessWidget {
  const DeckBackCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDeckCardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deckBackTop,
            AppColors.deckBackMid,
            AppColors.deckBackBottom,
          ],
          stops: [0, 0.45, 1],
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.6),
            blurRadius: 18,
          ),
        ],
      ),
    );
  }
}
