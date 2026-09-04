import 'dart:math';

import 'package:flutter/material.dart';

import 'models/clock_models.dart';
import 'painter_parts/clock_painter_labels.dart';

part 'painter_parts/clock_hands.dart';
part 'painter_parts/clock_minute_ring.dart';
part 'painter_parts/clock_month_ring.dart';
part 'painter_parts/clock_day_ring.dart';
part 'painter_parts/clock_effects.dart';
part 'painter_parts/clock_featured_effects.dart';
part 'painter_parts/clock_base_dial.dart';
part 'painter_parts/clock_inner_rings.dart';
part 'painter_parts/clock_ring_numbers.dart';
part 'painter_parts/clock_seconds_ring.dart';
part 'painter_parts/clock_ticks.dart';
part 'painter_parts/clock_week_ring.dart';

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
    double hourRadius = maxRadius * ClockRadiusFactors.hourBase;

    // 小秒盘跟随 hourRadius 调整
    final secondsCenter =
        center +
        Offset(0, -hourRadius * ClockRadiusFactors.secondsVerticalOffset);
    final secondsRadius = hourRadius * ClockRadiusFactors.seconds;

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
      _drawNumbers(canvas, center, hourRadius * ClockRadiusFactors.hourNumbers);
    }

    // 4. 地支
    if (_isVisible(ClockDialRing.branches)) {
      _drawEarthBranches(
        canvas,
        center,
        hourRadius * ClockRadiusFactors.branches,
      );
    }

    // 5. 经络
    if (_isVisible(ClockDialRing.meridians)) {
      _drawMeridians(canvas, center, hourRadius * ClockRadiusFactors.meridians);
    }

    // 5.5 分钟圈（放在心经圈以内）
    if (_isVisible(ClockDialRing.minutes)) {
      _drawMinuteNumbers(
        canvas,
        center,
        hourRadius * ClockRadiusFactors.minutes,
      );
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
      _drawFeaturedEarthBranches(
        canvas,
        center,
        hourRadius * ClockRadiusFactors.branches,
      );
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
