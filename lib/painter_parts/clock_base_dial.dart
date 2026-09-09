part of '../clock_painter.dart';

extension ClockPainterBaseDial on ClockPainter {
  void _drawDial(Canvas canvas, Offset center, double radius) {
    final outer = Paint()
      ..style = PaintingStyle.fill
      ..color = colorScheme.surfaceContainerLowest;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.outline;
    final inline1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          radius *
          ClockRadiusFactors.branches *
          ClockRadiusFactors.branchBandWidth
      ..color = colorScheme.secondaryContainer.withValues(alpha: 0.5);

    final dialRadius = radius * ClockRadiusFactors.hourOutline;
    canvas.drawCircle(center, dialRadius, outer);
    canvas.drawCircle(center, dialRadius, outline);
    if (_isVisible(ClockDialRing.branches)) {
      canvas.drawCircle(center, radius * ClockRadiusFactors.branches, inline1);
    }

    final emptyBranchRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          radius *
          (ClockRadiusFactors.branches +
              ClockRadiusFactors.branchNumbersOffset) *
          ClockRadiusFactors.branchNumbersTickHalfWidth *
          2
      ..color = colorScheme.tertiaryContainer.withValues(alpha: 0.58);
    if (_isVisible(ClockDialRing.branchNumbers)) {
      canvas.drawCircle(
        center,
        radius *
            (ClockRadiusFactors.branches +
                ClockRadiusFactors.branchNumbersOffset),
        emptyBranchRing,
      );
    }

    final branchIndex = ((now.hour + 1) % 24) ~/ 2;
    final centerDeg = (branchIndex * 2) * 15 + 180;
    final startAngleRad = _degToRad(centerDeg - 15) - pi / 2;
    final sweepAngleRad = _degToRad(30);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          radius *
          ClockRadiusFactors.branches *
          ClockRadiusFactors.branchBandWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.5);
    if (_isVisible(ClockDialRing.branches)) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-branchNumbersRotation);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius * ClockRadiusFactors.branches,
        ),
        startAngleRad,
        sweepAngleRad,
        false,
        highlightPaint,
      );
      canvas.restore();
    }

    final highlightMeridianPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          radius *
          ClockRadiusFactors.meridians *
          ClockRadiusFactors.meridianBandWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.3);
    if (_isVisible(ClockDialRing.meridians)) {
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius * ClockRadiusFactors.meridians,
        ),
        startAngleRad,
        sweepAngleRad,
        false,
        highlightMeridianPaint,
      );
    }

    final numberRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * ClockRadiusFactors.hourNumberBandWidth
      ..color = colorScheme.surfaceContainerHigh.withValues(alpha: 0.72);
    if (_isVisible(ClockDialRing.hours)) {
      canvas.drawCircle(
        center,
        radius * ClockRadiusFactors.hourNumbers,
        numberRingPaint,
      );
    }
  }
}
