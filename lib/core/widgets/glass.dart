import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.borderColor,
    this.blur = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  final Color? borderColor;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.55),
        borderRadius: shape,
        border: Border.all(
          color: borderColor ?? AppColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!blur || MediaQuery.disableAnimationsOf(context)) return panel;
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: panel,
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({required this.label, this.highlighted = false, super.key});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassPanel(
      radius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      borderColor: highlighted ? AppColors.lime.withValues(alpha: 0.8) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            const Icon(Icons.check_rounded, size: 14, color: AppColors.lime),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: highlighted ? AppColors.lime : AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
