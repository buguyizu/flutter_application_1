part of 'clock_painter.dart';

extension ClockPainterNumbers on ClockPainter {
  void _drawNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final selectedHourBgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFBDE3F8);

    final int currentHourNumber = now.hour == 0 ? 24 : now.hour;

    for (int i = 1; i <= 24; i++) {
      final angle = _degToRad(i * 15 + 180);
      final position = _pointOnCircle(center, radius, angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: i == currentHourNumber
              ? const Color(0xFF154360)
              : const Color(0xFF2C3E50),
          fontWeight: i == currentHourNumber
              ? FontWeight.w900
              : FontWeight.bold,
          fontSize: i == currentHourNumber ? 22 : 20,
        ),
      );

      textPainter.layout();

      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);

      if (i == currentHourNumber) {
        final bgRect = Rect.fromLTWH(
          offset.dx - 5,
          offset.dy - 3,
          textPainter.width + 10,
          textPainter.height + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
          selectedHourBgPaint,
        );
      }

      textPainter.paint(canvas, offset);
    }
  }
}
