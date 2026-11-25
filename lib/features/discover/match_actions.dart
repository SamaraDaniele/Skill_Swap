import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/line_icons.dart';

class MatchActionBar extends StatelessWidget {
  const MatchActionBar({
    required this.onUndo,
    required this.onPass,
    required this.onLike,
    required this.onSave,
    super.key,
  });

  final VoidCallback? onUndo;
  final VoidCallback onPass;
  final VoidCallback onLike;

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundAction(
            tooltip: l10n.undoAction,
            size: 54,
            style: _RoundStyle.graphite,
            onPressed: onUndo,
            child: LineIcon(
              LineIconShape.undo,
              size: 28,
              strokeWidth: 2,
              color: onUndo == null
                  ? AppColors.white.withValues(alpha: 0.35)
                  : AppColors.white,
            ),
          ),
          const SizedBox(width: 24),
          _RoundAction(
            tooltip: l10n.passAction,
            size: 76,
            style: _RoundStyle.white,
            onPressed: onPass,
            child: const CustomPaint(
              size: Size.square(28),
              painter: _CrossPainter(),
            ),
          ),
          const SizedBox(width: 26),
          _RoundAction(
            tooltip: l10n.likeAction,
            size: 80,
            style: _RoundStyle.neon,
            onPressed: onLike,
            child: const CustomPaint(
              size: Size.square(42),
              painter: _CheckPainter(),
            ),
          ),
          const SizedBox(width: 24),
          _RoundAction(
            tooltip: l10n.saveForLaterSoon,
            size: 54,
            style: _RoundStyle.graphite,
            onPressed: onSave,
            child: const LineIcon(
              LineIconShape.star,
              size: 30,
              strokeWidth: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RoundStyle { graphite, white, neon }

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.tooltip,
    required this.size,
    required this.style,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final double size;
  final _RoundStyle style;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  BoxDecoration get _decoration => switch (widget.style) {
    _RoundStyle.graphite => BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.graphite,
      border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
    ),
    _RoundStyle.white => BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.skipTop, AppColors.skipBottom],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.45),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    _RoundStyle.neon => BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [AppColors.neonHighlight, AppColors.neon, AppColors.neonDeep],
        stops: [0, 0.55, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.neon.withValues(alpha: 0.55),
          blurRadius: 28,
          spreadRadius: 1,
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        onTap: widget.onPressed,
        excludeSemantics: true,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: AppMotion.of(context, AppMotion.short),
          curve: AppMotion.curve,
          child: DecoratedBox(
            decoration: _decoration,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                onHighlightChanged: enabled ? _setPressed : null,
                child: SizedBox.square(
                  dimension: widget.size,
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => false;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.04, s * 0.52)
      ..lineTo(s * 0.36, s * 0.82)
      ..lineTo(s * 0.96, s * 0.2);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => false;
}
