part of '../clock_painter.dart';

extension ClockPainterHands on ClockPainter {
  void _drawHands(
    Canvas canvas,
    Offset center,
    double radius,
    Offset secondsCenter,
    double secondsRadius,
  ) {
    final hourAngle = _degToRad((now.hour + now.minute / 60) * 15) + pi;
    final minuteAngle = _degToRad(now.minute * 6);
    final secondAngle = _degToRad(now.second * 6);
    final isDarkTheme = colorScheme.brightness == Brightness.dark;

    final hourPaint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = isDarkTheme ? colorScheme.primaryContainer : Colors.black45;
    final minutePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = isDarkTheme ? colorScheme.secondaryContainer : Colors.black38;
    final secondPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = isDarkTheme ? colorScheme.error : Colors.red;

    final hourEnd = _pointOnCircle(center, radius * 0.84, hourAngle);
    final minuteEnd = _pointOnCircle(center, radius * 0.39, minuteAngle);
    final secondEnd = _pointOnCircle(
      secondsCenter,
      secondsRadius * 0.9,
      secondAngle,
    );

    if (isDarkTheme) {
      final hourGlow = Paint()
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = colorScheme.primary.withValues(alpha: 0.54)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final minuteGlow = Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = colorScheme.secondary.withValues(alpha: 0.48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final secondGlow = Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = colorScheme.error.withValues(alpha: 0.58)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(center, hourEnd, hourGlow);
      canvas.drawLine(center, minuteEnd, minuteGlow);
      canvas.drawLine(secondsCenter, secondEnd, secondGlow);
      canvas.drawCircle(secondsCenter, 7, secondGlow);
    }

    canvas.drawLine(center, hourEnd, hourPaint);
    canvas.drawLine(center, minuteEnd, minutePaint);
    canvas.drawLine(secondsCenter, secondEnd, secondPaint);
    canvas.drawCircle(secondsCenter, 3, secondPaint);
  }
}
