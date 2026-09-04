part of '../clock_painter.dart';

extension ClockPainterDayRing on ClockPainter {
  void _drawDaysOfYear(Canvas canvas, Offset center, double radius) {
    final totalDays = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final currentDayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final angleStep = 2 * pi / totalDays;
    final dayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.42);
    final currentDayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xFF2E86C1).withValues(alpha: 0.95);
    final midIntervalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.52);
    final monthBoundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = const Color(0xFF34474F).withValues(alpha: 0.7);
    if (hoveredRing == ClockDialRing.days) {
      _drawRingHoverBand(canvas, center, radius, ClockDialRing.days);
    }
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final labelData = <Map<String, dynamic>>[];
    for (int i = 0; i < totalDays; i++) {
      final dayNumber = i + 1;
      final dateForTick = DateTime(now.year, 1, dayNumber);
      final dayInMonth = dateForTick.day;
      final monthLastDay = DateTime(
        dateForTick.year,
        dateForTick.month + 1,
        0,
      ).day;
      final angle = i * angleStep + pi + angleStep / 2;
      final isCurrentDay = dayNumber == currentDayOfYear;
      final isMidIntervalDay = dayInMonth == 15;
      final isMonthStart = dayInMonth == 1;
      if (isMonthStart) {
        final boundaryAngle = angle - angleStep / 2;
        canvas.drawLine(
          _pointOnCircle(center, radius - 10, boundaryAngle),
          _pointOnCircle(center, radius + 1, boundaryAngle),
          monthBoundaryPaint,
        );
      }
      final tickOuter = isCurrentDay ? radius + 1 : radius;
      final tickInner =
          radius - (isCurrentDay ? 10 : (isMidIntervalDay ? 7 : 4.5));
      canvas.drawLine(
        _pointOnCircle(center, tickInner, angle),
        _pointOnCircle(center, tickOuter, angle),
        isCurrentDay
            ? currentDayPaint
            : (isMidIntervalDay ? midIntervalPaint : dayPaint),
      );
      if (dayInMonth == 15 || dayInMonth == monthLastDay || isCurrentDay) {
        labelData.add({
          'position': _pointOnCircle(center, radius - 16, angle),
          'angle': angle,
          'isCurrentDay': isCurrentDay,
          'text': isCurrentDay ? '$dayNumber／$totalDays' : '$dayNumber',
        });
      }
    }
    final currentLabelPosition =
        labelData.firstWhere(
              (label) => label['isCurrentDay'] as bool,
              orElse: () => <String, dynamic>{},
            )['position']
            as Offset? ??
        Offset.zero;
    for (final label in labelData) {
      final isCurrentDay = label['isCurrentDay'] as bool;
      if (!isCurrentDay &&
          (currentLabelPosition - (label['position'] as Offset)).distance <
              12) {
        continue;
      }
      final text = label['text'] as String;
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: isCurrentDay ? const Color(0xFF154360) : Colors.black38,
          fontSize: isCurrentDay ? 9 : 7,
          fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();
      final position = label['position'] as Offset;
      final angle = label['angle'] as double;
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
