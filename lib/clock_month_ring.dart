part of 'clock_painter.dart';

extension ClockPainterMonthRing on ClockPainter {
  void _drawMonths(Canvas canvas, Offset center, double radius) {
    final currentMonth = now.month;
    final totalDays = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final dayAngleStep = 2 * pi / totalDays;
    const yearBoundaryAngle = -11 * pi / 12;
    const seasonColors = <Color>[
      Color(0xFFBDBDBD),
      Color(0xFFB2EBF2),
      Color(0xFFB2EBF2),
      Color(0xFFB2EBF2),
      Color(0xFFF8C4C4),
      Color(0xFFF8C4C4),
      Color(0xFFF8C4C4),
      Color(0xFFE0E0E0),
      Color(0xFFE0E0E0),
      Color(0xFFE0E0E0),
      Color(0xFFBDBDBD),
      Color(0xFFBDBDBD),
    ];
    final highlightMonthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFBDE3F8);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black12;

    if (hoveredRing == ClockDialRing.months) {
      _drawRingHoverBand(canvas, center, radius, ClockDialRing.months);
    }
    var daysBeforeMonth = 0;
    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final monthDays = DateTime(now.year, month + 1, 0).day;
      final monthStartAngle =
          yearBoundaryAngle + daysBeforeMonth * dayAngleStep;
      final monthSweepAngle = monthDays * dayAngleStep;
      final monthCenterAngle = monthStartAngle + monthSweepAngle / 2;
      final seasonPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt
        ..color = seasonColors[i].withValues(alpha: 0.25);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        monthStartAngle - pi / 2,
        monthSweepAngle,
        false,
        seasonPaint,
      );
      if (month == currentMonth) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          monthStartAngle - pi / 2,
          monthSweepAngle,
          false,
          highlightMonthPaint,
        );
      }
      canvas.drawLine(
        _pointOnCircle(center, radius + 10, monthStartAngle),
        _pointOnCircle(center, radius - 10, monthStartAngle),
        linePaint,
      );
      final position = _pointOnCircle(center, radius, monthCenterAngle);
      textPainter.text = TextSpan(
        text: _monthLabel(i),
        style: TextStyle(
          color: month == currentMonth
              ? const Color(0xFF154360)
              : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(monthCenterAngle);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
      daysBeforeMonth += monthDays;
    }
  }
}
