part of '../clock_painter.dart';

extension ClockPainterInnerRings on ClockPainter {
  void _drawEarthBranches(Canvas canvas, Offset center, double radius) {
    final normalTextOpacity = 1 - _rotationPulse() * 0.72;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-branchNumbersRotation);
    canvas.translate(-center.dx, -center.dy);
    for (int i = 0; i < 24; i += 2) {
      final branchIndex = i ~/ 2;
      final angle = _degToRad(i * 15 + 180);
      final position = _pointOnCircle(center, radius, angle);
      textPainter.text = TextSpan(
        style: TextStyle(
          color: const Color(0xFF8E44AD).withValues(alpha: normalTextOpacity),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'Microsoft YaHei',
        ),
        children: [
          TextSpan(text: _branchLabel(branchIndex)),
          TextSpan(
            text: language == DisplayLanguage.english
                ? ''
                : language == DisplayLanguage.traditionalChinese
                ? '時'
                : '时',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(branchNumbersRotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawMeridians(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..color = const Color(0xFFD5DBDB).withValues(alpha: 0.28);
    canvas.drawCircle(center, radius, ringPaint);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < 24; i += 2) {
      final index = i ~/ 2;
      final angle = _degToRad(i * 15 + 180);
      final position = _pointOnCircle(center, radius, angle);
      textPainter.text = TextSpan(
        text: _meridianLabel(index),
        style: const TextStyle(
          color: Color(0xFF78909C),
          fontWeight: FontWeight.normal,
          fontSize: 10,
          fontFamily: 'Microsoft YaHei',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black26;
    for (int i = 0; i < 12; i++) {
      final angle = _degToRad(i * 30 + 15 + 180);
      canvas.drawLine(
        _pointOnCircle(center, radius + 15, angle),
        _pointOnCircle(center, radius - 15, angle),
        linePaint,
      );
    }
  }
}
