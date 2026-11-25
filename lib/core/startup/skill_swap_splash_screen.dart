import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart' show Ticker;
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/app_tokens.dart';

class SkillSwapSplashScreen extends StatefulWidget {
  const SkillSwapSplashScreen({
    required this.ready,
    required this.child,
    this.onFinished,
    super.key,
  });

  static const String logoAsset = AppAssets.logo;

  final bool ready;

  final Widget child;

  final VoidCallback? onFinished;

  @override
  State<SkillSwapSplashScreen> createState() => _SkillSwapSplashScreenState();
}

class _SkillSwapSplashScreenState extends State<SkillSwapSplashScreen>
    with TickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 1600);
  static const Duration _revealDuration = Duration(milliseconds: 600);
  static const Duration _reducedRevealDuration = Duration(milliseconds: 150);
  static const Duration _holdDuration = Duration(milliseconds: 1400);
  static const Duration _precacheTimeout = Duration(milliseconds: 300);
  static const int _minLogoDecodeWidth = 16;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: _revealDuration,
  );
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 350 / 1600, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _logoScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.82,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 350,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 300,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.04,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 300,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 650,
    ),
  ]).animate(_intro);

  late final Animation<double> _introGlow = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 350),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 600,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 650,
    ),
  ]).animate(_intro);

  late final Animation<double> _holdGlow = Tween(
    begin: 0.15,
    end: 0.4,
  ).animate(CurvedAnimation(parent: _hold, curve: Curves.easeInOut));

  late final Animation<double> _overlayOpacity = Tween(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic));

  late final Animation<Offset> _childSlide = Tween(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic));

  bool _started = false;
  bool _childSlideDisabled = false;
  bool _introDone = false;
  bool _holding = false;
  bool _revealing = false;
  bool _finished = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    if (MediaQuery.sizeOf(context).isEmpty) return;
    _started = true;
    if (_reduceMotion) {
      _intro.value = 1;
      _childSlideDisabled = true;
      _introDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
      return;
    }
    unawaited(
      precacheImage(_logoProvider(context), context)
          .timeout(_precacheTimeout, onTimeout: () {})
          .catchError((Object _) {})
          .whenComplete(_startIntro),
    );
  }

  static const double _maxStepMicros = 34000;

  Ticker? _introTicker;
  Ticker? _revealTicker;

  Ticker _drive(
    AnimationController controller,
    Duration duration,
    VoidCallback onDone,
  ) {
    final total = duration.inMicroseconds.toDouble();
    var last = Duration.zero;
    var progressed = 0.0;
    late final Ticker ticker;
    ticker = createTicker((elapsed) {
      final delta = (elapsed - last).inMicroseconds.toDouble();
      last = elapsed;
      progressed += math.min(delta, _maxStepMicros);
      controller.value = math.min(progressed / total, 1);
      if (progressed >= total) {
        ticker.stop();
        onDone();
      }
    });
    unawaited(ticker.start());
    return ticker;
  }

  void _startIntro() {
    if (!mounted) return;
    _introTicker = _drive(_intro, _introDuration, () {
      _introDone = true;
      _maybeReveal();
    });
  }

  @override
  void didUpdateWidget(SkillSwapSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready != oldWidget.ready) _maybeReveal();
  }

  void _maybeReveal() {
    if (!mounted || !_introDone || _revealing || _finished) return;
    if (!widget.ready) {
      if (!_reduceMotion && !_holding) {
        setState(() => _holding = true);
        _hold.repeat(reverse: true);
      }
      return;
    }
    _hold.stop();
    _revealing = true;
    _revealTicker = _drive(
      _reveal,
      _reduceMotion ? _reducedRevealDuration : _revealDuration,
      () {
        if (!mounted) return;
        setState(() => _finished = true);
        widget.onFinished?.call();
      },
    );
  }

  @override
  void dispose() {
    _introTicker?.dispose();
    _revealTicker?.dispose();
    _intro.dispose();
    _reveal.dispose();
    _hold.dispose();
    super.dispose();
  }

  static double _logoWidth(Size screen) =>
      math.min(screen.shortestSide * 0.78, 380);

  ImageProvider _logoProvider(BuildContext context) {
    final media = MediaQuery.of(context);
    final cacheWidth = (_logoWidth(media.size) * media.devicePixelRatio * 1.15)
        .round();
    return ResizeImage(
      const AssetImage(SkillSwapSplashScreen.logoAsset),
      width: math.max(cacheWidth, _minLogoDecodeWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: !_finished,
          child: SlideTransition(
            position: _childSlideDisabled
                ? const AlwaysStoppedAnimation(Offset.zero)
                : _childSlide,
            child: widget.child,
          ),
        ),
        if (!_finished)
          Positioned.fill(
            child: AbsorbPointer(
              child: FadeTransition(
                opacity: _overlayOpacity,
                child: ColoredBox(
                  color: AppColors.black,
                  child: Center(child: _buildLogo(context)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    final width = _logoWidth(MediaQuery.sizeOf(context));
    final title =
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        )?.appTitle ??
        '';
    return SizedBox(
      width: width * 1.4,
      height: width * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _holding ? _holdGlow : _introGlow,
            child: Container(
              width: width * 1.1,
              height: width * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.lime.withValues(alpha: 0.28),
                    AppColors.lime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _logoOpacity,
            child: ScaleTransition(
              scale: _logoScale,
              child: Semantics(
                label: title,
                image: true,
                child: Image(
                  image: _logoProvider(context),
                  width: width,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
