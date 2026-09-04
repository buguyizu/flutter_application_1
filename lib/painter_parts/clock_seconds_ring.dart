part of '../clock_painter.dart';

extension ClockPainterSecondsRing on ClockPainter {
  void _drawSecondsDial(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFECF0F1);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black45;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);
    if (hoveredRing == ClockDialRing.seconds) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ClockDialRing.seconds.hoverColor.withValues(alpha: 0.4),
      );
    }

    final majorPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF2C3E50);
    final minorPaint = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFBDC3C7);

    for (int i = 0; i < 60; i++) {
      final angle = _degToRad(i * 6);
      final isMajor = i % 5 == 0;
      final start = _pointOnCircle(center, radius, angle);
      final end = _pointOnCircle(
        center,
        isMajor ? radius - 6 : radius - 4,
        angle,
      );
      canvas.drawLine(start, end, isMajor ? majorPaint : minorPaint);
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 5; i <= 60; i += 5) {
      final angle = _degToRad(i * 6);
      final position = _pointOnCircle(center, radius - 14, angle);
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
}
