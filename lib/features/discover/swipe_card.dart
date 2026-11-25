import 'dart:math' as math;

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_tokens.dart';

const double kNextCardScale = 0.96;

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    required this.child,
    required this.onSwiped,
    required this.likeLabel,
    required this.passLabel,
    required this.semanticsLabel,
    this.enterFromLeft = false,
    this.borderRadius = AppRadius.xl,
    super.key,
  });

  final Widget child;
  final ValueChanged<bool> onSwiped;
  final String likeLabel;
  final String passLabel;

  final String semanticsLabel;

  final bool enterFromLeft;

  final double borderRadius;

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset> _animation = const AlwaysStoppedAnimation(Offset.zero);
  Offset _offset = Offset.zero;
  double _width = 0;

  bool _deciding = false;

  bool _confirming = false;

  bool _settled = false;

  late bool _pendingEnter;

  bool get isDeciding => _deciding;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() => setState(() => _offset = _animation.value));
    _pendingEnter = widget.enterFromLeft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _settled = true);
      if (_pendingEnter) {
        _pendingEnter = false;
        _animateTo(Offset.zero);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(Offset target, {VoidCallback? onDone}) {
    _animation = Tween(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));
    _controller
      ..duration = AppMotion.of(context, AppMotion.medium)
      ..forward(from: 0).whenCompleteOrCancel(() {
        if (mounted) onDone?.call();
      });
  }

  bool fling({required bool liked}) {
    if (_deciding || _width == 0) return false;
    _deciding = true;
    if (liked) setState(() => _confirming = true);
    final out = Offset((liked ? 1 : -1) * _width * 1.4, _offset.dy);
    if (liked && !MediaQuery.disableAnimationsOf(context)) {
      Future<void>.delayed(AppMotion.short, () {
        if (mounted) _animateTo(out, onDone: () => widget.onSwiped(true));
      });
    } else {
      _animateTo(out, onDone: () => widget.onSwiped(liked));
    }
    return true;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_deciding) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final passedThreshold = _offset.dx.abs() > _width * 0.3;
    final flung = velocity.abs() > 900;
    if (!passedThreshold && !flung) {
      _animateTo(Offset.zero);
      return;
    }
    final liked = flung ? velocity > 0 : _offset.dx > 0;
    _deciding = true;
    _animateTo(
      Offset((liked ? 1 : -1) * _width * 1.4, _offset.dy),
      onDone: () => widget.onSwiped(liked),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        if (_pendingEnter && _width > 0) _offset = Offset(-_width * 1.2, 0);
        final progress = _width == 0
            ? 0.0
            : (_offset.dx / (_width * 0.3)).clamp(-1.0, 1.0).toDouble();
        final approval = _confirming ? 1.0 : math.max(0.0, progress);
        return Semantics(
          container: true,
          label: widget.semanticsLabel,
          customSemanticsActions: {
            CustomSemanticsAction(label: widget.likeLabel): () =>
                fling(liked: true),
            CustomSemanticsAction(label: widget.passLabel): () =>
                fling(liked: false),
          },
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              if (!_deciding) _controller.stop();
            },
            onHorizontalDragUpdate: (d) {
              if (_deciding) return;
              setState(() => _offset += Offset(d.delta.dx, d.delta.dy * 0.2));
            },
            onHorizontalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: _offset,
              child: Transform.rotate(
                angle: _width == 0 ? 0 : _offset.dx / _width * (math.pi / 18),
                child: AnimatedScale(
                  scale: _confirming
                      ? 1.02
                      : (_settled || widget.enterFromLeft ? 1 : kNextCardScale),
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.curve,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      RepaintBoundary(child: widget.child),
                      if (approval > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  widget.borderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.neon.withValues(
                                    alpha: approval,
                                  ),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neon.withValues(
                                      alpha: 0.4 * approval,
                                    ),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (progress != 0)
                        Positioned(
                          top: AppSpacing.xxl,
                          right: AppSpacing.xxl,
                          child: Opacity(
                            opacity: progress.abs(),
                            child: _DecisionStamp(
                              label: progress > 0
                                  ? widget.likeLabel
                                  : widget.passLabel,
                              color: progress > 0
                                  ? AppColors.neon
                                  : AppColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecisionStamp extends StatelessWidget {
  const _DecisionStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.45),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: color, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
