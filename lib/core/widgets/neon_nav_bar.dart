import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';
import 'line_icons.dart';

class NeonNavItem {
  const NeonNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.badgeCount = 0,
    this.badgeSemantics,
  });

  final LineIconShape icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  final int badgeCount;

  final String? badgeSemantics;
}

class NeonNavBar extends StatelessWidget {
  const NeonNavBar({required this.items, super.key});

  final List<NeonNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navBar,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labelScaler = _labelScaler(context, constraints.maxWidth);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in items)
                    Expanded(
                      child: _NavItem(item: item, labelScaler: labelScaler),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  TextScaler _labelScaler(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    if (!width.isFinite || items.isEmpty) return scaler;
    final slot = width / items.length - 2 * _NavItem.sidePadding;
    var style = DefaultTextStyle.of(context).style
        .merge(_NavItem.labelStyle(true));
    if (MediaQuery.boldTextOf(context)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    var fit = 1.0;
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > slot) fit = math.min(fit, slot / painter.width);
      painter.dispose();
    }
    if (fit >= 1) return scaler;
    final scale = scaler.scale(_NavItem.fontSize) / _NavItem.fontSize;
    return TextScaler.linear(math.max(math.min(scale, 1), scale * fit));
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.labelScaler});

  final NeonNavItem item;
  final TextScaler labelScaler;

  static const double fontSize = 12.5;
  static const double sidePadding = 2;

  static TextStyle labelStyle(bool selected) => TextStyle(
    fontSize: fontSize,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final color = item.selected ? AppColors.neon : AppColors.navInactive;
    final glow = item.selected
        ? [Shadow(color: AppColors.neon.withValues(alpha: 0.7), blurRadius: 12)]
        : null;
    final badge = item.badgeCount;
    final label = [
      item.label,
      if (badge > 0 && item.badgeSemantics != null) item.badgeSemantics!,
    ].join(', ');
    return Semantics(
      button: true,
      selected: item.selected,
      label: label,
      onTap: item.onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: item.onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  LineIcon(
                    item.icon,
                    size: 28,
                    color: color,
                    glow: item.selected,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -9,
                      top: -7,
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
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
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
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: labelScaler,
                  style: labelStyle(item.selected)
                      .copyWith(color: color, shadows: glow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
