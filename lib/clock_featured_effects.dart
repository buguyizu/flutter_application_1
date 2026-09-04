part of 'clock_painter.dart';

extension ClockPainterFeaturedEffects on ClockPainter {
  void _drawFeaturedEarthBranches(
    Canvas canvas,
    Offset center,
    double branchRadius,
  ) {
    final pulse = _rotationPulse();
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
      final position = _pointOnCircle(center, branchRadius, angle);
      textPainter.text = TextSpan(
        style: TextStyle(
          color: const Color(0xFF6C3483).withValues(alpha: pulse),
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFamily: 'Microsoft YaHei',
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: pulse), blurRadius: 3),
          ],
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

  void _drawFeaturedYakshaGenerals(
    Canvas canvas,
    Offset center,
    double hourRadius,
  ) {
    final pulse = _rotationPulse();
    final generalRadius = hourRadius * 0.68 + 30;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-branchNumbersRotation);
    canvas.translate(-center.dx, -center.dy);
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
            color: const Color(0xFF7D6608).withValues(alpha: pulse),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: pulse),
                blurRadius: 3,
              ),
            ],
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
