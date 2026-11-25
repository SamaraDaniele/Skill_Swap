import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/line_icons.dart';
import '../profile/profile.dart';
import '../profile/skills.dart';
import 'knowledge_banner.dart';
import 'knowledge_match.dart';
import '../../core/utils/person_name.dart';

const double kDeckCardRadius = 24;

const double kDeckTilt = 0.042;

class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.me,
    required this.profile,
    this.onDetails,
    this.labelled = true,
    super.key,
  });

  final UserProfile me;
  final UserProfile profile;

  final bool labelled;

  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final match = KnowledgeMatch.between(me, profile);
    final wanted = match?.iCanTeach.firstOrNull ?? profile.learn.firstOrNull;
    final score = Compatibility.score(me, profile);
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDeckCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.neon.withValues(alpha: 0.30),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kDeckCardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CardPhoto(profile: profile),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0.20),
                    AppColors.black.withValues(alpha: 0),
                    AppColors.black.withValues(alpha: 0),
                    AppColors.black.withValues(alpha: 0.62),
                    AppColors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.18, 0.46, 0.68, 1],
                ),
              ),
            ),
            const _NeonCorner(),
            if (wanted != null && !largeText)
              Positioned(
                top: 14,
                left: 14,
                right: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _WantsTag(skillId: wanted),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              top: largeText ? 16 : 84,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  child: _Details(
                    profile: profile,
                    match: match,
                    wanted: wanted,
                    score: score,
                    stacked: largeText,
                    onDetails: onDetails,
                  ),
                ),
              ),
            ),
            const IgnorePointer(
              child: CustomPaint(painter: _CardBorderPainter()),
            ),
          ],
        ),
      ),
    );
    if (!labelled) return card;
    return Semantics(
      container: true,
      label: l10n.profileCardLabel(profile.name),
      child: card,
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = PersonName.initials(profile.name);
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.photoFallbackTop,
            AppColors.photoFallbackMid,
            AppColors.photoFallbackBottom,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: const Alignment(0, -0.3),
          child: Text(
            initials,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: constraints.hasBoundedHeight
                  ? math.min(96, constraints.maxHeight * 0.16)
                  : 96,
              fontWeight: FontWeight.w800,
              color: AppColors.textOnPhotoMuted,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
    final bytes = profile.photo;
    if (bytes == null) return ExcludeSemantics(child: fallback);
    return ExcludeSemantics(
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _NeonCorner extends StatelessWidget {
  const _NeonCorner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.15, 0.1),
            colors: [
              AppColors.neon.withValues(alpha: 0.80),
              AppColors.neon.withValues(alpha: 0.38),
              AppColors.neon.withValues(alpha: 0.10),
              AppColors.neon.withValues(alpha: 0),
            ],
            stops: const [0, 0.22, 0.42, 0.62],
          ),
        ),
      ),
    );
  }
}

class _CardBorderPainter extends CustomPainter {
  const _CardBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const width = 1.8;
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.neon,
          AppColors.neon.withValues(alpha: 0.75),
          AppColors.white.withValues(alpha: 0.35),
          AppColors.neon.withValues(alpha: 0.70),
          AppColors.neon,
        ],
        stops: const [0, 0.3, 0.55, 0.82, 1],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(kDeckCardRadius - width / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CardBorderPainter oldDelegate) => false;
}

class _WantsTag extends StatelessWidget {
  const _WantsTag({required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 7, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.inkTag.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_outlined, color: AppColors.neon, size: 24),
          const SizedBox(width: 13),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.wantsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                Text(
                  Skills.label(l10n, skillId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neon,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
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

class _Details extends StatelessWidget {
  const _Details({
    required this.profile,
    required this.match,
    required this.wanted,
    required this.score,
    required this.stacked,
    required this.onDetails,
  });

  final UserProfile profile;
  final KnowledgeMatch? match;
  final String? wanted;
  final int score;

  final bool stacked;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wanted = this.wanted;
    final panels = [
      if (wanted != null)
        (
          flex: 59,
          panel: _StatPanel(
            icon: const _TargetIcon(),
            label: l10n.goalLabel,
            value: l10n.goalLearn(Skills.label(l10n, wanted)),
            valueColor: AppColors.neon,
            maxLines: stacked ? 2 : 1,
          ),
        ),
      if (score > 0)
        (
          flex: 41,
          panel: _StatPanel(
            icon: const Icon(
              Icons.signal_cellular_alt_rounded,
              color: AppColors.neon,
              size: 26,
            ),
            label: l10n.compatibilityLabel,
            value: '$score%',
            valueColor: AppColors.white,
            maxLines: stacked ? 2 : 1,
          ),
        ),
    ];
    final match = this.match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                        shadows: [
                          Shadow(color: AppColors.textShadow, blurRadius: 12),
                        ],
                      ),
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textOnPhoto,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onDetails != null)
              IconButton(
                tooltip: l10n.profileDetailsAction,
                onPressed: onDetails,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const LineIcon(LineIconShape.info, size: 30),
              ),
          ],
        ),
        if (panels.isNotEmpty && stacked) ...[
          for (final p in panels) ...[const SizedBox(height: 8), p.panel],
        ] else if (panels.isNotEmpty) ...[
          const SizedBox(height: 11),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, p) in panels.indexed) ...[
                  if (i > 0) const SizedBox(width: 11),
                  Expanded(flex: p.flex, child: p.panel),
                ],
              ],
            ),
          ),
        ],
        if (match != null) ...[
          const SizedBox(height: 10),
          KnowledgeBanner(match: match, other: profile),
        ],
      ],
    );
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.maxLines = 1,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
      decoration: BoxDecoration(
        color: AppColors.inkPanel.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox.square(dimension: 26, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textOnPhotoMuted,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _TargetIcon extends StatelessWidget {
  const _TargetIcon();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: CustomPaint(size: Size.square(26), painter: _TargetPainter()),
  );
}

class _TargetPainter extends CustomPainter {
  const _TargetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = AppColors.neon
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round;
    final center = Offset(s * 0.45, s * 0.55);
    canvas
      ..drawArc(
        Rect.fromCircle(center: center, radius: s * 0.38),
        -math.pi / 6,
        math.pi * 5 / 3,
        false,
        paint,
      )
      ..drawCircle(center, s * 0.19, paint)
      ..drawCircle(center, s * 0.04, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    final tip = Offset(s * 0.9, s * 0.1);
    canvas
      ..drawLine(center, tip, paint)
      ..drawLine(tip, Offset(s * 0.66, s * 0.12), paint)
      ..drawLine(tip, Offset(s * 0.88, s * 0.34), paint);
  }

  @override
  bool shouldRepaint(_TargetPainter oldDelegate) => false;
}
