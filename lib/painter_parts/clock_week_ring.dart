part of '../clock_painter.dart';

extension ClockPainterWeekRing on ClockPainter {
  void _drawWeeks(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = const Color(0xFFF4F6F6);
    canvas.drawCircle(center, radius - 7, ringPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final currentDayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final currentWeek = ((currentDayOfYear - now.weekday + 10) / 7)
        .floor()
        .clamp(1, 52);
    final highlightWeekPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFBDE3F8);

    if (hoveredRing == ClockDialRing.weeks) {
      _drawRingHoverBand(canvas, center, radius - 7, ClockDialRing.weeks);
    }

    const weekCount = 52;
    final angleStep = 2 * pi / weekCount;
    final startAngleOffset = pi + angleStep / 2;
    for (int i = 0; i < weekCount; i++) {
      final angle = i * angleStep + startAngleOffset;
      if (i + 1 == currentWeek) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 7),
          angle - angleStep / 2 - pi / 2,
          angleStep,
          false,
          highlightWeekPaint,
        );
      }
      textPainter.text = TextSpan(
        text: i + 1 == currentWeek ? _weekLabel(i + 1) : '${i + 1}',
        style: TextStyle(
          color: i + 1 == currentWeek
              ? const Color(0xFF154360)
              : Colors.black26,
          fontSize: i + 1 == currentWeek ? 9 : 7,
          fontWeight: i + 1 == currentWeek
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
      textPainter.layout();
      final position = _pointOnCircle(center, radius - 7, angle);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }
}
