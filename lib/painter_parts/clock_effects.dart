part of '../clock_painter.dart';

extension ClockPainterEffects on ClockPainter {
  void _drawRotatingPageRays(
    Canvas canvas,
    Offset center,
    Size size,
    double outerRadius,
  ) {
    final pulse = _rotationPulse();
    final rayStartRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final rayEndRadius = sqrt(
      size.width * size.width + size.height * size.height,
    );
    const rayCount = 60;
    for (int index = 0; index < rayCount; index++) {
      final angle = -branchNumbersRotation + index * 2 * pi / rayCount;
      final isMajorRay = index % 4 == 0;
      final start = _pointOnCircle(center, rayStartRadius, angle);
      final end = _pointOnCircle(center, rayEndRadius, angle);
      final rayPaint = Paint()
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = isMajorRay ? 20 : 6
        ..color = const Color(
          0xFFFFD56A,
        ).withValues(alpha: (isMajorRay ? 0.34 : 0.12) * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMajorRay ? 6 : 2);
      canvas.drawLine(start, end, rayPaint);
      if (isMajorRay) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.butt
            ..color = const Color(0xFFFFF4B8).withValues(alpha: 0.72 * pulse),
        );
      }
    }
  }

  void _drawBranchAndGeneralCelebration(
    Canvas canvas,
    Offset center,
    double outerRadius,
  ) {
    final branchRadius = ClockDialRing.branches.radiusFor(outerRadius);
    final generalRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final bandRadius = (branchRadius + generalRadius) / 2;
    final bandWidth = generalRadius - branchRadius + 52;
    final bandRect = Rect.fromCircle(center: center, radius: bandRadius);
    final phase = branchNumbersRotation;
    final progress = (phase / (2 * pi)).clamp(0.0, 1.0);
    final settle = Curves.easeInCubic.transform(
      ((1 - progress) / 0.18).clamp(0.0, 1.0),
    );
    final pulse = _rotationPulse();
    final branchIndex = ((now.hour + 1) % 24) ~/ 2;
    final selectedStartAngle =
        _degToRad(branchIndex * 30 + 165) - pi / 2 - phase;

    canvas.drawCircle(
      center,
      bandRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth
        ..color = const Color(0xFFFFC857).withValues(alpha: 0.16 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth - 10
      ..color = const Color(0xFFFFD56A).withValues(alpha: 0.24 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawArc(
      bandRect,
      selectedStartAngle - pi / 1.55,
      pi / 1.55,
      false,
      trailPaint,
    );
    final selectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth - 8
      ..color = const Color(0xFFFFE09A).withValues(alpha: 0.36 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(
      bandRect,
      selectedStartAngle,
      pi / 6 * (0.55 + 0.45 * settle),
      false,
      selectedPaint,
    );
    final crownPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth - 18
      ..color = const Color(0xFFFFF4B8).withValues(alpha: 0.98 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawArc(bandRect, selectedStartAngle, pi / 6, false, crownPaint);
    for (var index = 0; index < 14; index++) {
      final trailProgress = index / 13;
      final angle = selectedStartAngle - trailProgress * pi / 1.7;
      final shimmer = 1 - trailProgress * 0.7;
      final particleRadius =
          branchRadius + (index % 3) * (generalRadius - branchRadius) / 2;
      canvas.drawCircle(
        Offset(
          center.dx + cos(angle) * particleRadius,
          center.dy + sin(angle) * particleRadius,
        ),
        1 + shimmer * 3.2,
        Paint()
          ..color = const Color(
            0xFFFFE6A7,
          ).withValues(alpha: (0.12 + shimmer * 0.8) * settle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawBranchAndGeneralSpotlight(
    Canvas canvas,
    Offset center,
    double outerRadius,
  ) {
    final branchRadius = ClockDialRing.branches.radiusFor(outerRadius);
    final generalRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final innerEdge = branchRadius - 24;
    final outerEdge = generalRadius + 18;
    final bandRadius = (innerEdge + outerEdge) / 2;
    final bandWidth = outerEdge - innerEdge;
    final pulse = _rotationPulse();
    canvas.saveLayer(null, Paint());
    canvas.drawCircle(
      center,
      outerRadius + 14,
      Paint()..color = Colors.white.withValues(alpha: 0.50 * pulse),
    );
    canvas.drawCircle(
      center,
      bandRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth + 4
        ..blendMode = BlendMode.clear,
    );
    canvas.restore();
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandWidth + 18
      ..color = const Color(0xFFFFD56A).withValues(alpha: 0.68 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, bandRadius, glowPaint);
  }
}
