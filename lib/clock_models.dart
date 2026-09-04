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

extension ClockDialRingMetrics on ClockDialRing {
  double radiusFor(double outerRadius) {
    final hourRadius = outerRadius * 0.86;
    return switch (this) {
      ClockDialRing.months => outerRadius,
      ClockDialRing.weeks => outerRadius * 0.975 - 7,
      ClockDialRing.days => outerRadius * 0.925,
      ClockDialRing.hours => hourRadius * 0.91,
      ClockDialRing.branchNumbers => hourRadius * 0.68 + 30,
      ClockDialRing.branches => hourRadius * 0.68,
      ClockDialRing.meridians => hourRadius * 0.56,
      ClockDialRing.minutes => hourRadius * 0.45 + 12,
      ClockDialRing.seconds => hourRadius * 0.15,
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

  double get hoverWidth => switch (this) {
    ClockDialRing.months => 22,
    ClockDialRing.weeks => 16,
    ClockDialRing.days => 10,
    ClockDialRing.hours => 28,
    ClockDialRing.branchNumbers => 26,
    ClockDialRing.branches => 38,
    ClockDialRing.meridians => 32,
    ClockDialRing.minutes => 12,
    ClockDialRing.seconds => 0,
  };

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
