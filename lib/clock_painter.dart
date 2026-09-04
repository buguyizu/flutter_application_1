import 'dart:math';

import 'package:flutter/material.dart';

import 'clock_models.dart';
import 'clock_painter_labels.dart';

part 'clock_hands.dart';
part 'clock_minute_ring.dart';
part 'clock_month_ring.dart';
part 'clock_day_ring.dart';
part 'clock_effects.dart';
part 'clock_featured_effects.dart';
part 'clock_base_dial.dart';
part 'clock_inner_rings.dart';
part 'clock_ring_numbers.dart';
part 'clock_seconds_ring.dart';
part 'clock_ticks.dart';
part 'clock_week_ring.dart';

class ClockPainter extends CustomPainter {
  final DateTime now;
  final ClockDialRing? hoveredRing;
  final Set<ClockDialRing> visibleRings;
  final DisplayLanguage language;
  final ColorScheme colorScheme;
  final bool isBranchNumbersRotating;
  final double branchNumbersRotation;
  String _branchLabel(int index) => switch (language) {
    DisplayLanguage.chinese => earthBranches[index],
    DisplayLanguage.traditionalChinese => earthBranches[index],
    DisplayLanguage.english => englishEarthBranches[index],
    DisplayLanguage.japanese => earthBranches[index],
  };

  String _meridianLabel(int index) => switch (language) {
    DisplayLanguage.chinese => meridians[index],
    DisplayLanguage.traditionalChinese => const [
      '膽經',
      '肝經',
      '肺經',
      '大腸經',
      '胃經',
      '脾經',
      '心經',
      '小腸經',
      '膀胱經',
      '腎經',
      '心包經',
      '三焦經',
    ][index],
    DisplayLanguage.english => englishMeridians[index],
    DisplayLanguage.japanese => meridians[index],
  };

  String _monthLabel(int index) => switch (language) {
    DisplayLanguage.chinese => '${index + 1}月',
    DisplayLanguage.traditionalChinese => '${index + 1}月',
    DisplayLanguage.english => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][index],
    DisplayLanguage.japanese => '${index + 1}月',
  };

  String _generalLabel(int index) => switch (language) {
    DisplayLanguage.chinese => '${yakshaGeneralsByDialPosition[index]}大将',
    DisplayLanguage.traditionalChinese =>
      '${yakshaGeneralsByDialPosition[index]}大將',
    DisplayLanguage.english => romanizedYakshaGeneralsByDialPosition[index],
    DisplayLanguage.japanese => '${yakshaGeneralsByDialPosition[index]}大将',
  };

  String _weekLabel(int number) => switch (language) {
    DisplayLanguage.chinese => '$number周',
    DisplayLanguage.traditionalChinese => '$number週',
    DisplayLanguage.english => 'W$number',
    DisplayLanguage.japanese => '$number週',
  };

  ClockPainter(
    this.now, {
    this.hoveredRing,
    this.visibleRings = const {
      ClockDialRing.months,
      ClockDialRing.weeks,
      ClockDialRing.days,
      ClockDialRing.hours,
      ClockDialRing.branchNumbers,
      ClockDialRing.branches,
      ClockDialRing.meridians,
      ClockDialRing.minutes,
      ClockDialRing.seconds,
    },
    this.language = DisplayLanguage.chinese,
    required this.colorScheme,
    this.isBranchNumbersRotating = false,
    this.branchNumbersRotation = 0,
  });

  bool _isVisible(ClockDialRing ring) => visibleRings.contains(ring);

  double _rotationPulse() {
    if (!isBranchNumbersRotating) {
      return 0;
    }
    final progress = (branchNumbersRotation / (2 * pi)).clamp(0.0, 1.0);
    final fadeIn = Curves.easeOutCubic.transform(
      (progress / 0.14).clamp(0.0, 1.0),
    );
    final fadeOut = Curves.easeInCubic.transform(
      ((1 - progress) / 0.18).clamp(0.0, 1.0),
    );
    return fadeIn * fadeOut;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    // 重新规划半径，为外层腾出空间
    // 原来 radius 充满了几乎整个屏幕 (min(w,h)/2 - 10)
    // 现在我们要在这个空间里塞入更多层，所以内部的“大表盘”需要缩小
    double maxRadius = min(size.width, size.height) / 2 - 10;

    // 1. 最外层：月份圈
    if (_isVisible(ClockDialRing.months)) {
      _drawMonths(canvas, center, maxRadius);
    }

    // 2. 周数圈 - 位于月份圈内侧（每年52周）
    double dayOfYearRadius = maxRadius * 0.975;
    if (_isVisible(ClockDialRing.weeks)) {
      _drawWeeks(canvas, center, dayOfYearRadius);
    }

    // 3. 年天数圈 - 位于周数圈内侧（365/366天）
    double weekRadius = maxRadius * 0.925;
    if (_isVisible(ClockDialRing.days)) {
      _drawDaysOfYear(canvas, center, weekRadius);
    }

    if (isBranchNumbersRotating &&
        _isVisible(ClockDialRing.branchNumbers) &&
        _isVisible(ClockDialRing.branches)) {
      _drawRotatingPageRays(canvas, center, size, maxRadius);
    }

    // 3. 24小时表盘 (原内容作为核心) - 位于月份圈内侧
    double hourRadius = maxRadius * 0.86;

    // 小秒盘跟随 hourRadius 调整
    final secondsCenter = center + Offset(0, -hourRadius * 0.22);
    final secondsRadius = hourRadius * 0.15;

    // 绘制层级 (从下到上)

    // 背景与外框 (基于 hourRadius)
    _drawDial(canvas, center, hourRadius * 0.97);
    if (isBranchNumbersRotating &&
        _isVisible(ClockDialRing.branchNumbers) &&
        _isVisible(ClockDialRing.branches)) {
      _drawBranchAndGeneralCelebration(canvas, center, maxRadius);
    }
    _drawHoveredInnerRing(canvas, center, maxRadius);

    // 刻度与数字
    _drawTicks(canvas, center, hourRadius);
    if (_isVisible(ClockDialRing.hours)) {
      _drawNumbers(canvas, center, hourRadius * 0.91);
    }

    // 4. 地支
    if (_isVisible(ClockDialRing.branches)) {
      _drawEarthBranches(canvas, center, hourRadius * 0.68);
    }

    // 5. 经络
    if (_isVisible(ClockDialRing.meridians)) {
      _drawMeridians(canvas, center, hourRadius * 0.56);
    }

    // 5.5 分钟圈（放在心经圈以内）
    if (_isVisible(ClockDialRing.minutes)) {
      _drawMiniteNumbers(canvas, center, hourRadius * 0.45);
    }

    // 6. 小秒盘
    if (_isVisible(ClockDialRing.seconds)) {
      _drawSecondsDial(canvas, secondsCenter, secondsRadius);
    }

    if (isBranchNumbersRotating &&
        _isVisible(ClockDialRing.branchNumbers) &&
        _isVisible(ClockDialRing.branches)) {
      _drawBranchAndGeneralSpotlight(canvas, center, maxRadius);
    }

    // 指针
    _drawHands(canvas, center, hourRadius, secondsCenter, secondsRadius);

    canvas.drawCircle(center, 6, Paint()..color = colorScheme.onSurface);
    if (isBranchNumbersRotating && _isVisible(ClockDialRing.branches)) {
      _drawFeaturedEarthBranches(canvas, center, hourRadius * 0.68);
    }
    if (isBranchNumbersRotating && _isVisible(ClockDialRing.branchNumbers)) {
      _drawFeaturedYakshaGenerals(canvas, center, hourRadius);
    }
  }

  void _drawHoveredInnerRing(Canvas canvas, Offset center, double radius) {
    final ring = hoveredRing;
    if (ring == null ||
        !_isVisible(ring) ||
        ring == ClockDialRing.months ||
        ring == ClockDialRing.weeks ||
        ring == ClockDialRing.days ||
        ring == ClockDialRing.seconds) {
      return;
    }
    _drawRingHoverBand(canvas, center, ring.radiusFor(radius), ring);
  }

  void _drawRingHoverBand(
    Canvas canvas,
    Offset center,
    double ringRadius,
    ClockDialRing ring,
  ) {
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.hoverWidth
        ..color = ring.hoverColor.withValues(alpha: 0.32),
    );
  }

  // ignore: unused_element
  void _legacyDrawRotatingPageRays(
    Canvas canvas,
    Offset center,
    Size size,
    double outerRadius,
  ) {
    final pulse = _rotationPulse();
    final rayStartRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final rayEndRadius = sqrt(
      size.width * size.width + size.height * size.height,
    );
    const rayCount = 60;

    for (int index = 0; index < rayCount; index += 1) {
      final angle = -branchNumbersRotation + index * 2 * pi / rayCount;
      final isMajorRay = index % 4 == 0;
      final start = _pointOnCircle(center, rayStartRadius, angle);
      final end = _pointOnCircle(center, rayEndRadius, angle);
      final rayPaint = Paint()
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = isMajorRay ? 20 : 6
        ..color = const Color(
          0xFFFFD56A,
        ).withValues(alpha: (isMajorRay ? 0.34 : 0.12) * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMajorRay ? 6 : 2);
      canvas.drawLine(start, end, rayPaint);
      if (isMajorRay) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.butt
            ..color = const Color(0xFFFFF4B8).withValues(alpha: 0.72 * pulse),
        );
      }
    }
  }

  // ignore: unused_element
  void _legacyDrawBranchAndGeneralCelebration(
    Canvas canvas,
    Offset center,
    double outerRadius,
  ) {
    final branchRadius = ClockDialRing.branches.radiusFor(outerRadius);
    final generalRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final bandRadius = (branchRadius + generalRadius) / 2;
    final bandWidth = generalRadius - branchRadius + 52;
    final bandRect = Rect.fromCircle(center: center, radius: bandRadius);
    final phase = branchNumbersRotation;
    final progress = (phase / (2 * pi)).clamp(0.0, 1.0);
    final fadeOut = Curves.easeInCubic.transform(
      ((1 - progress) / 0.18).clamp(0.0, 1.0),
    );
    final settle = fadeOut;
    final pulse = _rotationPulse();
    final branchIndex = ((now.hour + 1) % 24) ~/ 2;
    final selectedStartAngle =
        _degToRad(branchIndex * 30 + 165) - pi / 2 - phase;

    canvas.drawCircle(
      center,
      bandRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth
        ..color = const Color(0xFFFFC857).withValues(alpha: 0.16 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    trailPaint
      ..strokeWidth = bandWidth - 10
      ..color = const Color(0xFFFFD56A).withValues(alpha: 0.24 * pulse);
    canvas.drawArc(
      bandRect,
      selectedStartAngle - pi / 1.55,
      pi / 1.55,
      false,
      trailPaint,
    );

    final selectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth - 8
      ..color = const Color(0xFFFFE09A).withValues(alpha: 0.36 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(
      bandRect,
      selectedStartAngle,
      pi / 6 * (0.55 + 0.45 * settle),
      false,
      selectedPaint,
    );

    final crownPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandWidth - 18
      ..color = const Color(0xFFFFF4B8).withValues(alpha: 0.98 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawArc(bandRect, selectedStartAngle, pi / 6, false, crownPaint);

    for (var index = 0; index < 14; index += 1) {
      final trailProgress = index / 13;
      final angle = selectedStartAngle - trailProgress * pi / 1.7;
      final shimmer = 1 - trailProgress * 0.7;
      final particleRadius =
          branchRadius + (index % 3) * (generalRadius - branchRadius) / 2;
      final particleCenter = Offset(
        center.dx + cos(angle) * particleRadius,
        center.dy + sin(angle) * particleRadius,
      );
      canvas.drawCircle(
        particleCenter,
        1 + shimmer * 3.2,
        Paint()
          ..color = const Color(
            0xFFFFE6A7,
          ).withValues(alpha: (0.12 + shimmer * 0.8) * settle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ignore: unused_element
  void _legacyDrawBranchAndGeneralSpotlight(
    Canvas canvas,
    Offset center,
    double outerRadius,
  ) {
    final branchRadius = ClockDialRing.branches.radiusFor(outerRadius);
    final generalRadius = ClockDialRing.branchNumbers.radiusFor(outerRadius);
    final innerEdge = branchRadius - 24;
    final outerEdge = generalRadius + 18;
    final bandRadius = (innerEdge + outerEdge) / 2;
    final bandWidth = outerEdge - innerEdge;
    final pulse = _rotationPulse();

    canvas.saveLayer(null, Paint());
    canvas.drawCircle(
      center,
      outerRadius + 14,
      Paint()..color = Colors.white.withValues(alpha: 0.50 * pulse),
    );
    canvas.drawCircle(
      center,
      bandRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bandWidth + 4
        ..blendMode = BlendMode.clear,
    );
    canvas.restore();

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandWidth + 18
      ..color = const Color(0xFFFFD56A).withValues(alpha: 0.68 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, bandRadius, glowPaint);
  }

  // ignore: unused_element
  void _legacyDrawWeeks(Canvas canvas, Offset center, double radius) {
    // 绘制星期数字圈（一年52周）
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = const Color(0xFFF4F6F6);
    canvas.drawCircle(center, radius - 7, ringPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    int weekCount = 52;
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    int dayOfWeek = now.weekday; // 1=周一, 7=周日
    int currentWeek = ((dayOfYear - dayOfWeek + 10) / 7).floor();
    if (currentWeek > 52) currentWeek = 52;
    if (currentWeek < 1) currentWeek = 1;

    final Paint highlightWeekPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFBDE3F8); // 与小盘选中扇区一致

    if (hoveredRing == ClockDialRing.weeks) {
      _drawRingHoverBand(canvas, center, radius - 7, ClockDialRing.weeks);
    }

    final angleStep = 2 * pi / weekCount;
    // 让“第1周 与 最后一周”之间的分隔线落在正下方。
    final startAngleOffset = pi + angleStep / 2;

    for (int i = 0; i < weekCount; i++) {
      final angle = i * angleStep + startAngleOffset;

      if (i + 1 == currentWeek) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 7),
          angle -
              angleStep / 2 -
              pi / 2, // drawArc 0 is 3 o'clock, so -pi/2 to start from top
          angleStep,
          false,
          highlightWeekPaint,
        );
      }

      textPainter.text = TextSpan(
        text: i + 1 == currentWeek ? _weekLabel(i + 1) : '${i + 1}',
        style: TextStyle(
          color: (i + 1 == currentWeek)
              ? const Color(0xFF154360)
              : Colors.black26,
          fontSize: (i + 1 == currentWeek) ? 9 : 7,
          fontWeight: (i + 1 == currentWeek)
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
      textPainter.layout();

      final position = _pointOnCircle(center, radius - 7, angle);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle); // 旋转文字
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  // ignore: unused_element
  void _legacyDrawDaysOfYear(Canvas canvas, Offset center, double radius) {
    final int totalDays = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final int currentDayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    final double angleStep = 2 * pi / totalDays;
    // 将“第1天”刻度放到正下方（6点钟方向），并保持与月份环对齐。
    final double yearBoundaryAngle = pi;
    final double startAngleOffset = yearBoundaryAngle + angleStep / 2;

    final Paint dayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.42);

    final Paint currentDayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xFF2E86C1).withValues(alpha: 0.95);

    final Paint midIntervalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.52);

    final Paint monthBoundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = const Color(0xFF34495E).withValues(alpha: 0.7);

    if (hoveredRing == ClockDialRing.days) {
      _drawRingHoverBand(canvas, center, radius, ClockDialRing.days);
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final List<Map<String, dynamic>> labelData = [];

    for (int i = 0; i < totalDays; i++) {
      final int dayNumber = i + 1;
      final DateTime dateForTick = DateTime(now.year, 1, dayNumber);
      final int dayInMonth = dateForTick.day;
      final int monthLastDay = DateTime(
        dateForTick.year,
        dateForTick.month + 1,
        0,
      ).day;
      final double angle = i * angleStep + startAngleOffset;
      final bool isCurrentDay = dayNumber == currentDayOfYear;
      final bool isMidIntervalDay = dayInMonth == 15;
      final bool isMonthStart = dayInMonth == 1;
      final bool showLabel =
          dayInMonth == 15 || dayInMonth == monthLastDay || isCurrentDay;

      if (isMonthStart) {
        final double boundaryAngle = angle - angleStep / 2;
        final Offset boundaryStart = _pointOnCircle(
          center,
          radius - 10.0,
          boundaryAngle,
        );
        final Offset boundaryEnd = _pointOnCircle(
          center,
          radius + 1.0,
          boundaryAngle,
        );
        canvas.drawLine(boundaryStart, boundaryEnd, monthBoundaryPaint);
      }

      final double tickOuter = isCurrentDay ? radius + 1.0 : radius;
      final double tickInner =
          radius - (isCurrentDay ? 10.0 : (isMidIntervalDay ? 7.0 : 4.5));
      final Offset start = _pointOnCircle(center, tickInner, angle);
      final Offset end = _pointOnCircle(center, tickOuter, angle);

      canvas.drawLine(
        start,
        end,
        isCurrentDay
            ? currentDayPaint
            : (isMidIntervalDay ? midIntervalPaint : dayPaint),
      );

      if (showLabel) {
        final Offset labelPosition = _pointOnCircle(center, radius - 16, angle);
        labelData.add({
          'position': labelPosition,
          'angle': angle,
          'isCurrentDay': isCurrentDay,
          'text': isCurrentDay ? '$dayNumber／$totalDays' : '$dayNumber',
        });
      }
    }

    final Offset currentLabelPosition =
        labelData.firstWhere(
              (label) => label['isCurrentDay'] as bool,
              orElse: () => <String, dynamic>{},
            )['position']
            as Offset? ??
        Offset.zero;

    for (int i = 0; i < labelData.length; i++) {
      final Map<String, dynamic> label = labelData[i];
      final bool isCurrentDay = label['isCurrentDay'] as bool;

      if (!isCurrentDay) {
        final Offset otherPosition = label['position'] as Offset;
        if ((currentLabelPosition - otherPosition).distance < 12.0) {
          continue;
        }
      }

      final String text = label['text'] as String;
      final double angle = label['angle'] as double;
      final Offset labelPosition = label['position'] as Offset;

      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: isCurrentDay ? const Color(0xFF154360) : Colors.black38,
          fontSize: isCurrentDay ? 9 : 7,
          fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(labelPosition.dx, labelPosition.dy);
      canvas.rotate(angle);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  // ignore: unused_element
  void _legacyDrawMonths(Canvas canvas, Offset center, double radius) {
    int currentMonth = now.month;
    final int totalDays = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final double dayAngleStep = 2 * pi / totalDays;
    // 与天数圈使用同一年度边界基准，保证月弧与天数刻度对齐。
    final double yearBoundaryAngle = -11 * pi / 12;

    final List<Color> seasonColors = <Color>[
      const Color(0xFFBDBDBD), // 1月 冬（深灰）
      const Color(0xFFB2EBF2), // 2月 春（浅青）
      const Color(0xFFB2EBF2), // 3月 春（浅青）
      const Color(0xFFB2EBF2), // 4月 春（浅青）
      const Color(0xFFF8C4C4), // 5月 夏（浅红）
      const Color(0xFFF8C4C4), // 6月 夏（浅红）
      const Color(0xFFF8C4C4), // 7月 夏（浅红）
      const Color(0xFFE0E0E0), // 8月 秋（浅灰）
      const Color(0xFFE0E0E0), // 9月 秋（浅灰）
      const Color(0xFFE0E0E0), // 10月 秋（浅灰）
      const Color(0xFFBDBDBD), // 11月 冬（深灰）
      const Color(0xFFBDBDBD), // 12月 冬（深灰）
    ];

    final Paint highlightMonthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFBDE3F8); // 与小盘选中扇区一致

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black12;

    if (hoveredRing == ClockDialRing.months) {
      _drawRingHoverBand(canvas, center, radius, ClockDialRing.months);
    }

    int daysBeforeMonth = 0;
    for (int i = 0; i < 12; i++) {
      final int month = i + 1;
      final int monthDays = DateTime(now.year, month + 1, 0).day;
      final double monthStartAngle =
          yearBoundaryAngle + daysBeforeMonth * dayAngleStep;
      final double monthSweepAngle = monthDays * dayAngleStep;
      final double monthCenterAngle = monthStartAngle + monthSweepAngle / 2;

      final Paint seasonPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt
        ..color = seasonColors[i].withValues(alpha: 0.25);

      // 四季背景分区：冬季为 11、12、1 月。
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

      // Draw separator lines
      final start = _pointOnCircle(center, radius + 10, monthStartAngle);
      final end = _pointOnCircle(center, radius - 10, monthStartAngle);
      canvas.drawLine(start, end, linePaint);

      final position = _pointOnCircle(center, radius, monthCenterAngle);

      textPainter.text = TextSpan(
        text: _monthLabel(i),
        style: TextStyle(
          color: (month == currentMonth)
              ? const Color(0xFF154360)
              : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(position.dx, position.dy);
      // 文字旋转方向：
      // 如果希望文字底部朝向圆心，则 rotate(angle)
      // 如果希望文字顶部朝向圆心，则 rotate(angle + pi)
      canvas.rotate(monthCenterAngle);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();

      daysBeforeMonth += monthDays;
    }
  }

  // ignore: unused_element
  void _legacyDrawDial(Canvas canvas, Offset center, double radius) {
    final Paint outer = Paint()
      ..style = PaintingStyle.fill
      ..color = colorScheme.surfaceContainerLowest;
    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.outline;
    final Paint inline1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..color = colorScheme.secondaryContainer.withValues(alpha: 0.5);
    // final Paint inline2 = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 1
    //   ..color = Colors.black45;

    canvas.drawCircle(center, radius, outer);
    canvas.drawCircle(center, radius, outline);
    if (_isVisible(ClockDialRing.branches)) {
      canvas.drawCircle(center, radius * 0.68, inline1);
    }
    final Paint emptyBranchRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = colorScheme.tertiaryContainer.withValues(alpha: 0.58);
    if (_isVisible(ClockDialRing.branchNumbers)) {
      canvas.drawCircle(center, radius * 0.68 + 30, emptyBranchRing);
    }

    // 高亮当前地支 (内层经络也一起高亮?)
    // 计算当前地支索引 (23:00-01:00 为子(0), 01:00-03:00 为丑(1)...)
    int branchIndex = ((now.hour + 1) % 24) ~/ 2;
    // 计算中心角度 (基于 i*15 + 180 的逻辑，其中 i = branchIndex * 2)
    double centerDeg = (branchIndex * 2) * 15 + 180;
    // 转换为 drawArc 所需的弧度 (0度在右侧，顺时针为正)
    // 我们的坐标系转换: standard = my - 90度 (即 - pi/2)
    // 扇形起始位置 = 中心角 - 15度(半个时辰)
    double startAngleRad = _degToRad(centerDeg - 15) - pi / 2;
    double sweepAngleRad = _degToRad(30);

    final Paint highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.5); // 金黄色高亮

    if (_isVisible(ClockDialRing.branches)) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-branchNumbersRotation);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.68),
        startAngleRad,
        sweepAngleRad,
        false,
        highlightPaint,
      );
      canvas.restore();
    }

    // 高亮当前经络 (经络圈半径0.56，宽度30)
    final Paint highlightMeridianPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.3); // 略淡一点

    if (_isVisible(ClockDialRing.meridians)) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.56),
        startAngleRad,
        sweepAngleRad,
        false,
        highlightMeridianPaint,
      );
    }

    // 为1-24小时数字添加一个浅色背景圆环
    final Paint numberRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          28 // 加宽一点以容纳数字
      ..color = colorScheme.surfaceContainerHigh.withValues(alpha: 0.72);
    if (_isVisible(ClockDialRing.hours)) {
      canvas.drawCircle(center, radius * 0.91, numberRingPaint);
    }

    // canvas.drawCircle(center, radius * 0.70, inline2);

    // canvas.drawCircle(center, radius * 0.70, inline2);
  }

  // ignore: unused_element
  void _legacyDrawTicks(Canvas canvas, Offset center, double radius) {
    final Paint hourPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF7F8C8D);
    final Paint branchPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black54;

    // 24小时刻度
    if (_isVisible(ClockDialRing.hours)) {
      final hourOutlineRadius = radius * 0.97;
      for (int i = 0; i < 24; i++) {
        final angle = _degToRad(i * 15 + 180);

        // 刻度外端与 24 小时圈的细黑实线完全重合。
        final start = _pointOnCircle(center, hourOutlineRadius, angle);
        final end = _pointOnCircle(center, hourOutlineRadius - 6, angle);
        canvas.drawLine(start, end, hourPaint);
      }
    }

    // 地支刻度
    if (_isVisible(ClockDialRing.branches)) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-branchNumbersRotation);
      canvas.translate(-center.dx, -center.dy);
      for (int i = 0; i < 12; i += 1) {
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
    for (int i = 0; i < 12; i += 1) {
      final angle = _degToRad(i * 30 + 180 + 15);
      final emptyRingStart = _pointOnCircle(center, generalRadius + 12, angle);
      final emptyRingEnd = _pointOnCircle(center, generalRadius - 12, angle);
      canvas.drawLine(emptyRingStart, emptyRingEnd, branchPaint);
    }

    final emptyRingTextPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final normalTextOpacity = 1 - _rotationPulse() * 0.72;
    for (int i = 0; i < 12; i += 1) {
      final cellCenterAngle = _degToRad(i * 30 + 180 + 30);
      final generalName = _generalLabel(i);
      for (
        int characterIndex = 0;
        characterIndex < generalName.length;
        characterIndex += 1
      ) {
        final characterAngle =
            cellCenterAngle +
            (characterIndex - (generalName.length - 1) / 2) * pi / 36;
        final position = _pointOnCircle(center, generalRadius, characterAngle);
        emptyRingTextPainter.text = TextSpan(
          text: generalName[characterIndex],
          style: TextStyle(
            color: const Color(0xFF5D6D7E).withValues(alpha: normalTextOpacity),
            fontSize: 11,
            fontWeight: FontWeight.normal,
          ),
        );
        emptyRingTextPainter.layout();
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(characterAngle);
        emptyRingTextPainter.paint(
          canvas,
          Offset(
            -emptyRingTextPainter.width / 2,
            -emptyRingTextPainter.height / 2,
          ),
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }

  // ignore: unused_element
  void _legacyDrawFeaturedEarthBranches(
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

  // ignore: unused_element
  void _legacyDrawFeaturedYakshaGenerals(
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
    for (int i = 0; i < 12; i += 1) {
      final cellCenterAngle = _degToRad(i * 30 + 180 + 30);
      final generalName = _generalLabel(i);
      for (
        int characterIndex = 0;
        characterIndex < generalName.length;
        characterIndex += 1
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

  // ignore: unused_element
  void _legacyDrawEarthBranches(Canvas canvas, Offset center, double radius) {
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  // ignore: unused_element
  void _legacyDrawMeridians(Canvas canvas, Offset center, double radius) {
    // 绘制经络圈背景
    final Paint ringPaint = Paint()
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
          color: Color(0xFF78909C), // 低对比度灰蓝
          fontWeight: FontWeight.normal,
          fontSize: 10,
          fontFamily: 'Microsoft YaHei',
        ),
      );

      textPainter.layout();
      // 旋转画布绘制文字，使其径向排列
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + pi / 2); // 旋转文字

      // 修正：让文字朝向中心或向外，这里让文字底部朝向中心
      // 注意：上面的 rotate 已经把坐标系转了。
      // angle 是位置角度。当 angle = 180 (正上方) -> 文字不旋转。
      // 需要仔细调整旋转逻辑。简单起见，这里先不旋转文字本身，只定点绘制。
      // 如果需要文字沿着圆弧弯曲，逻辑会复杂很多。
      // 这里如果只用 flat text，不用 rotate，直接画
      canvas.restore();

      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }

    // 绘制经络分隔线
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black26;

    for (int i = 0; i < 12; i++) {
      final angle = _degToRad(i * 30 + 15 + 180); // 偏移15度，画在两个时辰也就是经络之间
      final start = _pointOnCircle(center, radius + 15, angle);
      final end = _pointOnCircle(center, radius - 15, angle);
      canvas.drawLine(start, end, linePaint);
    }
  }

  // ignore: unused_element
  void _legacyDrawNumbers(Canvas canvas, Offset center, double radius) {
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

  // ignore: unused_element
  void _legacyDrawMiniteNumbers(Canvas canvas, Offset center, double radius) {
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

    // 0 在正上方；完整绘制 0-60 对应的分钟刻度（环上 60 个唯一位置）。
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

  // ignore: unused_element
  void _legacyDrawSecondsDial(Canvas canvas, Offset center, double radius) {
    // 绘制小秒盘背景
    final Paint bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFECF0F1); // 浅灰背景
    final Paint borderPaint = Paint()
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

    final Paint majorPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF2C3E50);
    final Paint minorPaint = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFBDC3C7);

    // 绘制小刻度
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

    // 绘制小数字 (5, 10, ... 60)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    // 修改为每 5 秒显示一个数字
    for (int i = 5; i <= 60; i += 5) {
      final angle = _degToRad(i * 6);
      // 放在刻度内侧
      final position = _pointOnCircle(
        center,
        radius - 14,
        angle,
      ); // 距离调整适应更小的半径
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 8, // 字号随半径缩小微调
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

  Offset _pointOnCircle(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * sin(angle),
      center.dy - radius * cos(angle),
    );
  }

  double _degToRad(double degree) => degree * pi / 180;

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) =>
      oldDelegate.now.second != now.second ||
      oldDelegate.hoveredRing != hoveredRing ||
      oldDelegate.visibleRings.length != visibleRings.length ||
      !oldDelegate.visibleRings.every(visibleRings.contains) ||
      oldDelegate.language != language ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.isBranchNumbersRotating != isBranchNumbersRotating ||
      oldDelegate.branchNumbersRotation != branchNumbersRotation;
}
