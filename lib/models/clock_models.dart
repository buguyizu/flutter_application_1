import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DisplayLanguage { chinese, traditionalChinese, english, japanese }

enum AppThemePreset {
  chronicleIndigo,
  jingshiJade,
  moonPhaseGold,
  cinnabarRed,
  midnightInk,
  bambooShade,
}

enum AppThemeOption {
  chronicleIndigoLight,
  jingshiJadeLight,
  moonPhaseGoldLight,
  cinnabarRedLight,
  midnightInkDark,
  bambooShadeDark,
}

extension AppThemePresetData on AppThemePreset {
  Color get seedColor => switch (this) {
    AppThemePreset.chronicleIndigo => const Color(0xFF3949AB),
    AppThemePreset.jingshiJade => const Color(0xFF00796B),
    AppThemePreset.moonPhaseGold => const Color(0xFFB7791F),
    AppThemePreset.cinnabarRed => const Color(0xFFC62828),
    AppThemePreset.midnightInk => const Color(0xFF263238),
    AppThemePreset.bambooShade => const Color(0xFF004D40),
  };
}

extension AppThemeOptionData on AppThemeOption {
  AppThemePreset get preset => switch (this) {
    AppThemeOption.chronicleIndigoLight => AppThemePreset.chronicleIndigo,
    AppThemeOption.jingshiJadeLight => AppThemePreset.jingshiJade,
    AppThemeOption.moonPhaseGoldLight => AppThemePreset.moonPhaseGold,
    AppThemeOption.cinnabarRedLight => AppThemePreset.cinnabarRed,
    AppThemeOption.midnightInkDark => AppThemePreset.midnightInk,
    AppThemeOption.bambooShadeDark => AppThemePreset.bambooShade,
  };

  ThemeMode get themeMode => switch (this) {
    AppThemeOption.midnightInkDark ||
    AppThemeOption.bambooShadeDark => ThemeMode.dark,
    _ => ThemeMode.light,
  };
}

enum ClockDialRing {
  months,
  weeks,
  days,
  hours,
  branchNumbers,
  branches,
  meridians,
  minutes,
  seconds,
}

enum MainDialMode { timeFlow, hexagrams }

abstract final class ClockRadiusFactors {
  static const weeks = 0.975;
  static const days = 0.925;
  static const weekBandWidth = 0.05;
  static const hourBase = 0.86;
  static const hourNumbers = 0.91;
  static const hourOutline = 0.97;
  static const hourTickLength = 0.015;
  static const hourNumberBandWidth = (hourOutline - hourNumbers) * 2;
  static const branches = 0.72;
  static const minutes = 0.45;
  static const seconds = 0.15;
  static const secondsVerticalOffset = 0.22;

  static const branchBandWidth = 0.125;
  static const meridianBandWidth = 0.15;
  static const meridians =
      branches * (1 - branchBandWidth / 2) / (1 + meridianBandWidth / 2);
  static const minuteOuterOffset = 0.03;
  static const branchTickHalfWidth = 0.0625;
  static const meridianTickHalfWidth = 0.075;
  static const branchNumbersOffset = 0.077;
  static const branchNumbersTickHalfWidth = 0.038;
}

extension ClockDialRingMetrics on ClockDialRing {
  double radiusFor(
    double outerRadius, {
    double hourBase = ClockRadiusFactors.hourBase,
  }) {
    final hourRadius = outerRadius * hourBase;
    return switch (this) {
      ClockDialRing.months => outerRadius,
      ClockDialRing.weeks =>
        outerRadius *
            (ClockRadiusFactors.weeks - ClockRadiusFactors.weekBandWidth / 2),
      ClockDialRing.days => outerRadius * ClockRadiusFactors.days,
      ClockDialRing.hours => hourRadius * ClockRadiusFactors.hourNumbers,
      ClockDialRing.branchNumbers =>
        hourRadius *
            (ClockRadiusFactors.branches +
                ClockRadiusFactors.branchNumbersOffset),
      ClockDialRing.branches => hourRadius * ClockRadiusFactors.branches,
      ClockDialRing.meridians => hourRadius * ClockRadiusFactors.meridians,
      ClockDialRing.minutes =>
        hourRadius *
            (ClockRadiusFactors.minutes + ClockRadiusFactors.minuteOuterOffset),
      ClockDialRing.seconds => hourRadius * ClockRadiusFactors.seconds,
    };
  }

  double get hitTolerance => switch (this) {
    ClockDialRing.months => 10,
    ClockDialRing.weeks => 7,
    ClockDialRing.days => 5,
    ClockDialRing.hours => 14,
    ClockDialRing.branchNumbers => 12,
    ClockDialRing.branches => 18,
    ClockDialRing.meridians => 15,
    ClockDialRing.minutes => 7,
    ClockDialRing.seconds => 0,
  };

  double hoverWidthFor(
    double outerRadius, {
    double hourBase = ClockRadiusFactors.hourBase,
  }) {
    final ringRadius = radiusFor(outerRadius, hourBase: hourBase);
    return switch (this) {
      ClockDialRing.months => 22,
      ClockDialRing.weeks => 16,
      ClockDialRing.days => math.max(28.0, outerRadius * 0.09),
      ClockDialRing.hours =>
        ringRadius * ClockRadiusFactors.hourNumberBandWidth,
      ClockDialRing.branchNumbers =>
        ringRadius * ClockRadiusFactors.branchNumbersTickHalfWidth * 2,
      ClockDialRing.branches => ringRadius * ClockRadiusFactors.branchBandWidth,
      ClockDialRing.meridians =>
        ringRadius * ClockRadiusFactors.meridianBandWidth,
      ClockDialRing.minutes => math.max(32.0, outerRadius * 0.11),
      ClockDialRing.seconds => 0,
    };
  }

  double hoverRadiusFor(
    double outerRadius, {
    double hourBase = ClockRadiusFactors.hourBase,
  }) {
    return switch (this) {
      ClockDialRing.days =>
        radiusFor(outerRadius, hourBase: hourBase) -
            hoverWidthFor(outerRadius, hourBase: hourBase) / 2,
      ClockDialRing.minutes =>
        radiusFor(outerRadius, hourBase: hourBase) -
            hoverWidthFor(outerRadius, hourBase: hourBase) / 2,
      _ => radiusFor(outerRadius, hourBase: hourBase),
    };
  }

  double hoverGlowExtensionFor(
    double outerRadius, {
    double hourBase = ClockRadiusFactors.hourBase,
  }) => math.max(16.0, hoverWidthFor(outerRadius, hourBase: hourBase) * 0.75);

  Color get hoverColor => switch (this) {
    ClockDialRing.months => const Color(0xFFFFD1DC),
    ClockDialRing.weeks => const Color(0xFFBDE3F8),
    ClockDialRing.days => const Color(0xFFC8F7C5),
    ClockDialRing.hours => const Color(0xFFBDE3F8),
    ClockDialRing.branchNumbers => const Color(0xFFFFE09A),
    ClockDialRing.branches => const Color(0xFFE8C7F3),
    ClockDialRing.meridians => const Color(0xFFB8F0E1),
    ClockDialRing.minutes => const Color(0xFFFFE0B2),
    ClockDialRing.seconds => const Color(0xFFFFE0B2),
  };
}
