import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

enum LineIconShape {
  bell,
  person,
  people,
  flame,
  layers,
  chat,
  star,
  info,
  undo,
}

class LineIcon extends StatelessWidget {
  const LineIcon(
    this.shape, {
    this.size = 24,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 1.7,
    this.glow = false,
    super.key,
  });

  final LineIconShape shape;
  final double size;
  final Color color;

  final double strokeWidth;

  final bool glow;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LineIconPainter(shape, color, strokeWidth, glow: glow),
      ),
    );
  }
}

class _LineIconPainter extends CustomPainter {
  const _LineIconPainter(
    this.shape,
    this.color,
    this.strokeWidth, {
    required this.glow,
  });

  final LineIconShape shape;
  final Color color;
  final double strokeWidth;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final (paths, dots) = _shape(shape);
    if (glow) {
      final halo = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      for (final p in paths) {
        canvas.drawPath(p, halo);
      }
    }
    for (final p in paths) {
      canvas.drawPath(p, stroke);
    }
    for (final (center, radius) in dots) {
      canvas.drawCircle(center, radius, fill);
    }
    canvas.restore();
  }

  static (List<Path>, List<(Offset, double)>) _shape(
    LineIconShape shape,
  ) => switch (shape) {
    LineIconShape.bell => (
      [
        Path()
          ..moveTo(6, 16.5)
          ..lineTo(6, 10.5)
          ..arcToPoint(const Offset(18, 10.5), radius: const .circular(6))
          ..lineTo(18, 16.5)
          ..lineTo(19.5, 18.5)
          ..lineTo(4.5, 18.5)
          ..close(),
        Path()
          ..moveTo(10, 21)
          ..arcToPoint(
            const Offset(14, 21),
            radius: const .circular(2.2),
            clockwise: false,
          ),
        Path()
          ..moveTo(12, 3)
          ..lineTo(12, 4.5),
      ],
      const [],
    ),
    LineIconShape.person => (
      [
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(12, 8), radius: 4)),
        Path()
          ..moveTo(4.5, 20.5)
          ..arcToPoint(
            const Offset(19.5, 20.5),
            radius: const .elliptical(7.5, 7),
          ),
      ],
      const [],
    ),
    LineIconShape.people => (
      [
        Path()..addOval(
          Rect.fromCircle(center: const Offset(12, 8.2), radius: 3.3),
        ),
        Path()
          ..moveTo(6, 20)
          ..arcToPoint(const Offset(18, 20), radius: const .elliptical(6, 6.2)),
        Path()..addOval(
          Rect.fromCircle(center: const Offset(5.4, 9.6), radius: 2.3),
        ),
        Path()
          ..moveTo(1.6, 17.2)
          ..arcToPoint(
            const Offset(7.1, 13.9),
            radius: const .elliptical(4.3, 4.3),
          ),
        Path()..addOval(
          Rect.fromCircle(center: const Offset(18.6, 9.6), radius: 2.3),
        ),
        Path()
          ..moveTo(16.9, 13.9)
          ..arcToPoint(
            const Offset(22.4, 17.2),
            radius: const .elliptical(4.3, 4.3),
          ),
      ],
      const [],
    ),
    LineIconShape.flame => (
      [
        Path()
          ..moveTo(12, 2.5)
          ..cubicTo(12.6, 6.2, 18.5, 8.6, 18.5, 14.5)
          ..arcToPoint(const Offset(5.5, 14.5), radius: const .circular(6.5))
          ..cubicTo(5.5, 11.6, 7, 9.6, 8.4, 8.4)
          ..cubicTo(8.3, 10.6, 9.4, 12, 10.8, 12.3)
          ..cubicTo(10.2, 8.6, 11, 5.2, 12, 2.5)
          ..close(),
      ],
      const [],
    ),
    LineIconShape.layers => (
      [
        Path()
          ..moveTo(12, 3)
          ..lineTo(21, 7.8)
          ..lineTo(12, 12.6)
          ..lineTo(3, 7.8)
          ..close(),
        Path()
          ..moveTo(3, 12)
          ..lineTo(12, 16.8)
          ..lineTo(21, 12),
        Path()
          ..moveTo(3, 16.2)
          ..lineTo(12, 21)
          ..lineTo(21, 16.2),
      ],
      const [],
    ),
    LineIconShape.chat => (
      [
        Path()..addRRect(RRect.fromLTRBR(3, 4, 21, 17, const .circular(3))),
        Path()
          ..moveTo(8, 17)
          ..lineTo(7, 21)
          ..lineTo(12.5, 17),
      ],
      const [
        (Offset(8, 10.5), 1.15),
        (Offset(12, 10.5), 1.15),
        (Offset(16, 10.5), 1.15),
      ],
    ),
    LineIconShape.star => ([_star()], const []),
    LineIconShape.info => (
      [
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9.5)),
        Path()
          ..moveTo(12, 11)
          ..lineTo(12, 16.5),
      ],
      const [(Offset(12, 7.6), 1.2)],
    ),
    LineIconShape.undo => (
      [
        Path()..addArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 8.5),
          math.pi,
          -math.pi * 1.8,
        ),
        Path()
          ..moveTo(5, 2.9)
          ..lineTo(5, 7.1)
          ..lineTo(9.2, 7.1),
      ],
      const [],
    ),
  };

  static Path _star() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? 9.6 : 4.3;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        12 + radius * math.cos(angle),
        12.8 + radius * math.sin(angle),
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_LineIconPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}
