import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_tokens.dart';

abstract final class NeonColors {
  static const Color lime = Color(0xFFC6FF00);

  static const Color limeHot = Color(0xFFE6FF7A);

  static const Color limeDeep = Color(0xFFA8F000);

  static const Color muted = Color(0xFFB3B3B3);

  static const Color hairline = Color(0x47FFFFFF);
}

void paintGlowRRect(
  Canvas canvas,
  RRect rrect, {
  required double width,
  required double alpha,
  int layers = 8,
  Shader Function(double alpha)? shader,
}) {
  final step = alpha / layers;
  final paint = Paint()..style = PaintingStyle.stroke;
  for (var i = 0; i < layers; i++) {
    paint.strokeWidth = width * (layers - i) / layers;
    if (shader != null) {
      paint.shader = shader(step);
    } else {
      paint.color = NeonColors.lime.withValues(alpha: step);
    }
    canvas.drawRRect(rrect, paint);
  }
}

class NeonBackdropPainter extends CustomPainter {
  const NeonBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.black);

    _glowingEllipse(
      canvas,
      center: Offset(w * 1.24, -h * 0.09),
      radius: w * 0.62,
      squash: 0.72,
      angle: -0.55,
      fill: 1.25,
    );
    _fade(
      canvas,
      Rect.fromLTWH(w * 0.45, 0, w * 0.55, h * 0.33),
      from: const Alignment(-1, 0.6),
      to: const Alignment(0.1, -0.2),
    );

    _spill(canvas, Offset(w * 0.30, h * 1.03), w * 0.45, 0.16);
    _glowingEllipse(
      canvas,
      center: Offset(-w * 0.22, h * 1.06),
      radius: w * 0.70,
      squash: 0.68,
      angle: 0.62,
    );
    _glowingEllipse(
      canvas,
      center: Offset(-w * 0.24, h * 1.08),
      radius: w * 0.44,
      squash: 0.70,
      angle: 0.62,
      intensity: 0.45,
    );
    _fade(
      canvas,
      Rect.fromLTWH(0, h * 0.70, w * 0.70, h * 0.30),
      from: const Alignment(1, -0.4),
      to: const Alignment(-0.1, 0.3),
    );
  }

  void _glowingEllipse(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double squash,
    required double angle,
    double intensity = 1,
    double fill = 1,
  }) {
    const lime = NeonColors.lime;
    Color a(Color color, double alpha) =>
        color.withValues(alpha: alpha * intensity);
    final outer = radius * 1.06;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle)
      ..scale(1, squash)
      ..drawCircle(
        Offset.zero,
        outer,
        Paint()
          ..shader = RadialGradient(
            colors: [
              a(lime, 0),
              a(lime, 0),
              a(lime, 0.18 * fill),
              a(lime, 0.50 * fill),
              a(NeonColors.limeHot, 1),
              a(lime, 0.55),
              a(lime, 0.14),
              a(lime, 0),
            ],
            stops: const [0, 0.55, 0.84, 0.925, 0.943, 0.953, 0.975, 1],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: outer)),
      )
      ..restore();
  }

  void _spill(Canvas canvas, Offset center, double radius, double alpha) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            NeonColors.lime.withValues(alpha: alpha),
            NeonColors.lime.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _fade(
    Canvas canvas,
    Rect rect, {
    required Alignment from,
    required Alignment to,
  }) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: from,
          end: to,
          colors: [AppColors.black, AppColors.black.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(NeonBackdropPainter oldDelegate) => false;
}

class SkillSwapLogo extends StatelessWidget {
  const SkillSwapLogo({required this.semanticLabel, super.key});

  final String semanticLabel;

  static const _assetSize = Size(1536, 1024);
  static const _symbol = Rect.fromLTRB(390, 90, 1235, 860);
  static const double _symbolHeight = 54;

  @override
  Widget build(BuildContext context) {
    final scale = _symbolHeight / _symbol.height;
    final imageWidth = _assetSize.width * scale;
    final imageHeight = _assetSize.height * scale;
    final boxWidth = _symbol.width * scale;
    final alignX = 2 * (_symbol.left * scale) / (imageWidth - boxWidth) - 1;
    final alignY =
        2 * (_symbol.top * scale) / (imageHeight - _symbolHeight) - 1;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: boxWidth,
                height: _symbolHeight,
                child: OverflowBox(
                  maxWidth: imageWidth,
                  maxHeight: imageHeight,
                  alignment: Alignment(alignX, alignY),
                  child: Image.asset(
                    AppAssets.logo,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                    cacheWidth:
                        (imageWidth * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Skill',
                      style: TextStyle(color: AppColors.white),
                    ),
                    TextSpan(text: ' '),
                    TextSpan(
                      text: 'Swap',
                      style: TextStyle(color: NeonColors.lime),
                    ),
                  ],
                ),
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 35,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonGlowBar extends StatelessWidget {
  const NeonGlowBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 4,
      decoration: BoxDecoration(
        color: NeonColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: NeonColors.lime.withValues(alpha: 0.8),
            blurRadius: 8,
          ),
          BoxShadow(
            color: NeonColors.lime.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class GlassNeonCard extends StatelessWidget {
  const GlassNeonCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
    this.radius = 30,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: NeonColors.lime.withValues(alpha: 0.30),
            blurRadius: 22,
          ),
          BoxShadow(
            color: NeonColors.lime.withValues(alpha: 0.10),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GlassNeonCardPainter(radius),
        child: RepaintBoundary(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _GlassNeonCardPainter extends CustomPainter {
  const _GlassNeonCardPainter(this.radius);

  final double radius;

  static const _borderAlphas = [1.0, 0.72, 0.62, 0.78, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    const lime = NeonColors.lime;

    Shader border(double scale) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        for (final alpha in _borderAlphas)
          lime.withValues(alpha: alpha * scale),
      ],
    ).createShader(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA182006), Color(0xFA0A0D05), Color(0xFA0E1306)],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );

    canvas
      ..save()
      ..clipRRect(rrect);
    paintGlowRRect(canvas, rrect, width: 56, alpha: 0.16, layers: 10);
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-1, -1),
            radius: 0.9,
            colors: [lime.withValues(alpha: 0.12), lime.withValues(alpha: 0)],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(1, 1),
            radius: 0.7,
            colors: [lime.withValues(alpha: 0.07), lime.withValues(alpha: 0)],
          ).createShader(rect),
      )
      ..restore();

    paintGlowRRect(
      canvas,
      rrect,
      width: 9,
      alpha: 0.55,
      layers: 6,
      shader: border,
    );
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = border(1),
    );
  }

  @override
  bool shouldRepaint(_GlassNeonCardPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

void paintGlassCapsule(
  Canvas canvas,
  Rect rect, {
  required Color borderColor,
  double focusGlow = 0,
  double borderWidth = 1,
}) {
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
  const lime = NeonColors.lime;

  if (focusGlow > 0) {
    paintGlowRRect(
      canvas,
      rrect,
      width: 14,
      alpha: 0.45 * focusGlow,
      layers: 4,
    );
  }

  canvas
    ..drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xC72C3027), Color(0xC717190F)],
        ).createShader(rect),
    )
    ..save()
    ..clipRRect(rrect)
    ..translate(rect.center.dx, rect.bottom)
    ..scale(1, 0.32)
    ..drawCircle(
      Offset.zero,
      rect.width * 0.48,
      Paint()
        ..shader =
            RadialGradient(
              colors: [lime.withValues(alpha: 0.16), lime.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: rect.width * 0.48),
            ),
    )
    ..restore()
    ..drawRRect(
      rrect.deflate(borderWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );

  canvas
    ..save()
    ..clipRect(
      Rect.fromLTRB(rect.left, rect.center.dy, rect.right, rect.bottom + 2),
    )
    ..drawRRect(
      rrect.deflate(borderWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 0.4
        ..shader = LinearGradient(
          colors: [
            lime.withValues(alpha: 0.10),
            lime.withValues(alpha: 0.75),
            lime.withValues(alpha: 0.10),
          ],
        ).createShader(rect),
    )
    ..restore();
}

class NeonCapsuleBorder extends InputBorder {
  const NeonCapsuleBorder({
    super.borderSide = const BorderSide(color: NeonColors.hairline),
    this.focusGlow = 0,
  });

  final double focusGlow;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  NeonCapsuleBorder copyWith({BorderSide? borderSide, double? focusGlow}) =>
      NeonCapsuleBorder(
        borderSide: borderSide ?? this.borderSide,
        focusGlow: focusGlow ?? this.focusGlow,
      );

  @override
  NeonCapsuleBorder scale(double t) =>
      NeonCapsuleBorder(borderSide: borderSide.scale(t), focusGlow: focusGlow);

  RRect _shape(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_shape(rect).deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_shape(rect));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is NeonCapsuleBorder
      ? NeonCapsuleBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          focusGlow: a.focusGlow + (focusGlow - a.focusGlow) * t,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is NeonCapsuleBorder
      ? NeonCapsuleBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
          focusGlow: focusGlow + (b.focusGlow - focusGlow) * t,
        )
      : super.lerpTo(b, t);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    paintGlassCapsule(
      canvas,
      rect,
      borderColor: borderSide.color,
      borderWidth: borderSide.width,
      focusGlow: focusGlow,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeonCapsuleBorder &&
      other.borderSide == borderSide &&
      other.focusGlow == focusGlow;

  @override
  int get hashCode => Object.hash(borderSide, focusGlow);
}

class NeonTextField extends StatelessWidget {
  const NeonTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.isPassword = false,
    this.suffix,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;

  final bool isPassword;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    const idle = NeonCapsuleBorder();
    final focused = NeonCapsuleBorder(
      borderSide: BorderSide(
        color: NeonColors.lime.withValues(alpha: 0.9),
        width: 1.2,
      ),
      focusGlow: 1,
    );
    final failed = NeonCapsuleBorder(borderSide: BorderSide(color: error));
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: isPassword ? TextInputType.visiblePassword : keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !isPassword,
      enableIMEPersonalizedLearning: !isPassword,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: NeonColors.lime,
      style: const TextStyle(color: AppColors.white, fontSize: 16.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16.5),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 18, end: 14),
          child: Icon(icon, color: const Color(0xFFE6E6E6), size: 23),
        ),
        prefixIconConstraints: const BoxConstraints(minHeight: 48),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: suffix,
              ),
        errorStyle: TextStyle(color: error, fontSize: 13),
        errorMaxLines: 2,
        enabledBorder: idle,
        disabledBorder: idle,
        focusedBorder: focused,
        errorBorder: failed,
        focusedErrorBorder: failed.copyWith(focusGlow: 0.6),
      ),
    );
  }
}

class NeonPrimaryButton extends StatefulWidget {
  const NeonPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<NeonPrimaryButton> createState() => _NeonPrimaryButtonState();
}

class _NeonPrimaryButtonState extends State<NeonPrimaryButton> {
  final _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  void _onStates() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.isLoading ? null : widget.onPressed;
    final duration = AppMotion.of(context, AppMotion.short);
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: duration,
      curve: AppMotion.curve,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: NeonColors.lime.withValues(alpha: _pressed ? 0.75 : 0.55),
              blurRadius: _pressed ? 16 : 20,
            ),
            BoxShadow(
              color: NeonColors.lime.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          statesController: _states,
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 10),
            ),
            shape: const WidgetStatePropertyAll(StadiumBorder()),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: const WidgetStatePropertyAll(NeonColors.lime),
            foregroundColor: const WidgetStatePropertyAll(AppColors.black),
            overlayColor: WidgetStatePropertyAll(
              AppColors.black.withValues(alpha: 0.08),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            backgroundBuilder: (context, states, child) => DecoratedBox(
              decoration: const ShapeDecoration(
                shape: StadiumBorder(),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NeonColors.limeHot,
                    NeonColors.lime,
                    NeonColors.limeDeep,
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
              child: child,
            ),
          ),
          child: widget.isLoading
              ? Semantics(
                  label: widget.label,
                  liveRegion: true,
                  child: const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.black,
                    ),
                  ),
                )
              : Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}

class NeonOrDivider extends StatelessWidget {
  const NeonOrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(height: 1, thickness: 1, color: Color(0xFF3A3D35)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E8E8E),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 8),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: const WidgetStatePropertyAll(BorderSide.none),
        foregroundColor: const WidgetStatePropertyAll(AppColors.white),
        overlayColor: WidgetStatePropertyAll(
          AppColors.white.withValues(alpha: 0.06),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500),
        ),
        backgroundBuilder: (context, states, child) => CustomPaint(
          painter: _CapsulePainter(
            focused: states.contains(WidgetState.focused),
          ),
          child: child,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.lg),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _CapsulePainter extends CustomPainter {
  const _CapsulePainter({required this.focused});

  final bool focused;

  @override
  void paint(Canvas canvas, Size size) => paintGlassCapsule(
    canvas,
    Offset.zero & size,
    borderColor: focused ? NeonColors.lime : NeonColors.hairline,
    focusGlow: focused ? 1 : 0,
  );

  @override
  bool shouldRepaint(_CapsulePainter oldDelegate) =>
      oldDelegate.focused != focused;
}

class GoogleGMark extends StatelessWidget {
  const GoogleGMark({this.size = 24, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _GoogleGPainter()),
  );
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    double rad(double degrees) => degrees * math.pi / 180;

    void arc(Color color, double from, double to) => canvas.drawArc(
      arcRect,
      rad(from),
      rad(to - from),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );

    arc(_blue, 0, 48);
    arc(_green, 46, 140);
    arc(_yellow, 138, 222);
    arc(_red, 220, 318);
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx - stroke * 0.05,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
