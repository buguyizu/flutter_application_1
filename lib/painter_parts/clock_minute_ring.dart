part of '../clock_painter.dart';

extension ClockPainterMinuteRing on ClockPainter {
  void _drawMiniteNumbers(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = colorScheme.outlineVariant;
    canvas.drawCircle(center, radius + 12, ringPaint);

    final majorTickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = colorScheme.outline;
    final minorTickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorScheme.outlineVariant;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 60; i++) {
      final angle = _degToRad(i * 6);
      final isMajor = i % 5 == 0;
      final tickOuter = radius + 12;
      final tickInner = tickOuter - (isMajor ? 6.5 : 3.5);
      final start = _pointOnCircle(center, tickInner, angle);
      final end = _pointOnCircle(center, tickOuter, angle);
      canvas.drawLine(start, end, isMajor ? majorTickPaint : minorTickPaint);
    }

    for (int i = 0; i < 60; i += 5) {
      final angle = _degToRad(i * 6);
      final position = _pointOnCircle(center, radius - 8, angle);
      final minuteText = i == 0 ? '0' : i.toString().padLeft(2, '0');

      textPainter.text = TextSpan(
        text: minuteText,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      );
      textPainter.layout();
      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }
}
