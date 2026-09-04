part of '../clock_painter.dart';

extension ClockPainterTicks on ClockPainter {
  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final hourPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF7F8C8D);
    final branchPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black54;

    if (_isVisible(ClockDialRing.hours)) {
      final hourOutlineRadius = radius * 0.97;
      for (int i = 0; i < 24; i++) {
        final angle = _degToRad(i * 15 + 180);
        final start = _pointOnCircle(center, hourOutlineRadius, angle);
        final end = _pointOnCircle(center, hourOutlineRadius - 6, angle);
        canvas.drawLine(start, end, hourPaint);
      }
    }

    if (_isVisible(ClockDialRing.branches)) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-branchNumbersRotation);
      canvas.translate(-center.dx, -center.dy);
      for (int i = 0; i < 12; i++) {
        final angle = _degToRad(i * 30 + 180 + 15);
        final start = _pointOnCircle(center, radius * 0.68 + 18, angle);
        final end = _pointOnCircle(center, radius * 0.68 - 18, angle);
        canvas.drawLine(start, end, branchPaint);
      }
      canvas.restore();
    }

    if (!_isVisible(ClockDialRing.branchNumbers)) {
      return;
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-branchNumbersRotation);
    canvas.translate(-center.dx, -center.dy);
    final generalRadius = radius * 0.68 + 30;
    for (int i = 0; i < 12; i++) {
      final angle = _degToRad(i * 30 + 180 + 15);
      canvas.drawLine(
        _pointOnCircle(center, generalRadius + 12, angle),
        _pointOnCircle(center, generalRadius - 12, angle),
        branchPaint,
      );
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final normalTextOpacity = 1 - _rotationPulse() * 0.72;
    for (int i = 0; i < 12; i++) {
      final cellCenterAngle = _degToRad(i * 30 + 180 + 30);
      final generalName = _generalLabel(i);
      for (
        int characterIndex = 0;
        characterIndex < generalName.length;
        characterIndex++
      ) {
        final characterAngle =
            cellCenterAngle +
            (characterIndex - (generalName.length - 1) / 2) * pi / 36;
        final position = _pointOnCircle(center, generalRadius, characterAngle);
        textPainter.text = TextSpan(
          text: generalName[characterIndex],
          style: TextStyle(
            color: const Color(0xFF5D6D7E).withValues(alpha: normalTextOpacity),
            fontSize: 11,
            fontWeight: FontWeight.normal,
          ),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(characterAngle);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }
}
