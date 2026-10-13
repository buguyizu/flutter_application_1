import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'clock_models.dart';

/// UI 配置：时钟缩放、主盘模式、可见圈层、面板状态、动画
class UiConfig {
  final double clockScale;
  final String mainDialMode; // 'timeFlow' | 'hexagrams'
  final List<String> visibleRings;
  final bool leftDialColumnCollapsed;
  final bool yuanHuiExpanded;
  final bool branchMeridianExpanded;
  final bool protectionExpanded;
  final bool rightInfoColumnCollapsed;
  final double animationDurationSeconds;
  final double hexagramRotation;
  final double titleFontSize;
  final double bodyFontSize;
  final double smallFontSize;
  final double panelTitleFontSize;
  final double textFontSize;
  final double? textFontWeight;
  final double accentColorValue;
  final double effectColorValue;
  final double infoPanelTitleColorValue;
  final double panelSpacing;
  final double clockHorizontalPadding;
  final double containerMargin;
  final double containerPadding;
  final double highlightStrokeWidth;
  final double outlineWidth;
  final double animationDurationMs;
  final String fontFamily;
  final double subtitleColorValue;
  final double subtitleFontSize;
  final double subtitleFontWeight;
  final double smallDialWidth;
  final double smallDialHeight;
  final ResponsiveUiConfig responsive;

  const UiConfig({
    this.clockScale = 1.3,
    this.mainDialMode = 'timeFlow',
    this.visibleRings = const [
      'months',
      'weeks',
      'days',
      'hours',
      'branchNumbers',
      'branches',
      'meridians',
      'minutes',
      'seconds',
    ],
    this.leftDialColumnCollapsed = false,
    this.yuanHuiExpanded = true,
    this.branchMeridianExpanded = true,
    this.protectionExpanded = false,
    this.rightInfoColumnCollapsed = false,
    this.animationDurationSeconds = 10.0,
    this.hexagramRotation = 0.0,
    this.titleFontSize = 22.0,
    this.bodyFontSize = 20.0,
    this.smallFontSize = 16.0,
    this.panelTitleFontSize = 18.0,
    this.textFontSize = 22.0,
    this.textFontWeight = 700.0,
    this.accentColorValue = 0xFFFFD56A,
    this.effectColorValue = 0xFFF1C40F,
    this.infoPanelTitleColorValue = 0xFF3949AB,
    this.panelSpacing = 8.0,
    this.clockHorizontalPadding = 30.0,
    this.containerMargin = 8.0,
    this.containerPadding = 8.0,
    this.highlightStrokeWidth = 6.0,
    this.outlineWidth = 2.0,
    this.animationDurationMs = 220.0,
    this.fontFamily = 'Microsoft YaHei',
    this.subtitleColorValue = 0xFF37474F,
    this.subtitleFontSize = 12.0,
    this.subtitleFontWeight = 700.0,
    this.smallDialWidth = 176.0,
    this.smallDialHeight = 210.0,
    this.responsive = const ResponsiveUiConfig(),
  });

  factory UiConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UiConfig();
    // Support new nested structure and old flat structure for backward compatibility
    final clock = json['clock'] as Map<String, dynamic>? ?? {};
    final typography = json['typography'] as Map<String, dynamic>? ?? {};
    final layout = json['layout'] as Map<String, dynamic>? ?? {};
    final colors = json['colors'] as Map<String, dynamic>? ?? {};
    final smallDial = json['smallDial'] as Map<String, dynamic>? ?? {};
    final subtitle = typography['subtitle'] as Map<String, dynamic>? ?? {};
    final responsive = json['responsive'] as Map<String, dynamic>?;

    return UiConfig(
      clockScale:
          (clock['scale'] as num?)?.toDouble() ??
          (json['clockScale'] as num?)?.toDouble() ??
          1.3,
      mainDialMode:
          (clock['mainDialMode'] as String?) ??
          (json['mainDialMode'] as String?) ??
          'timeFlow',
      visibleRings:
          (clock['visibleRings'] as List?)?.cast<String>() ??
          (json['visibleRings'] as List?)?.cast<String>() ??
          const [
            'months',
            'weeks',
            'days',
            'hours',
            'branchNumbers',
            'branches',
            'meridians',
            'minutes',
            'seconds',
          ],
      leftDialColumnCollapsed:
          (clock['leftDialColumnCollapsed'] as bool?) ??
          (json['leftDialColumnCollapsed'] as bool?) ??
          false,
      yuanHuiExpanded:
          (clock['yuanHuiExpanded'] as bool?) ??
          (json['yuanHuiExpanded'] as bool?) ??
          true,
      branchMeridianExpanded:
          (clock['branchMeridianExpanded'] as bool?) ??
          (json['branchMeridianExpanded'] as bool?) ??
          true,
      protectionExpanded:
          (clock['protectionExpanded'] as bool?) ??
          (json['protectionExpanded'] as bool?) ??
          false,
      rightInfoColumnCollapsed:
          (clock['rightInfoColumnCollapsed'] as bool?) ??
          (json['rightInfoColumnCollapsed'] as bool?) ??
          false,
      animationDurationSeconds:
          (clock['animationDurationSeconds'] as num?)?.toDouble() ??
          (json['animationDurationSeconds'] as num?)?.toDouble() ??
          10.0,
      hexagramRotation:
          (clock['hexagramRotation'] as num?)?.toDouble() ??
          (json['hexagramRotation'] as num?)?.toDouble() ??
          0.0,
      animationDurationMs:
          (clock['animationDurationMs'] as num?)?.toDouble() ??
          (json['animationDurationMs'] as num?)?.toDouble() ??
          220.0,
      titleFontSize:
          (typography['titleFontSize'] as num?)?.toDouble() ??
          (json['titleFontSize'] as num?)?.toDouble() ??
          22.0,
      bodyFontSize:
          (typography['bodyFontSize'] as num?)?.toDouble() ??
          (json['bodyFontSize'] as num?)?.toDouble() ??
          20.0,
      smallFontSize:
          (typography['smallFontSize'] as num?)?.toDouble() ??
          (json['smallFontSize'] as num?)?.toDouble() ??
          16.0,
      panelTitleFontSize:
          (typography['panelTitleFontSize'] as num?)?.toDouble() ??
          (json['panelTitleFontSize'] as num?)?.toDouble() ??
          18.0,
      textFontSize:
          (typography['textFontSize'] as num?)?.toDouble() ??
          (json['textFontSize'] as num?)?.toDouble() ??
          22.0,
      textFontWeight: (typography['textFontWeight'] as num?)?.toDouble(),
      fontFamily:
          (typography['fontFamily'] as String?) ??
          (json['fontFamily'] as String?) ??
          'Microsoft YaHei',
      subtitleColorValue:
          (subtitle['colorValue'] as int?)?.toDouble() ??
          (json['subtitleColorValue'] as int?)?.toDouble() ??
          0xFF37474F,
      subtitleFontSize:
          (subtitle['fontSize'] as num?)?.toDouble() ??
          (json['subtitleFontSize'] as num?)?.toDouble() ??
          12.0,
      subtitleFontWeight:
          (subtitle['fontWeight'] as num?)?.toDouble() ??
          (json['subtitleFontWeight'] as num?)?.toDouble() ??
          700.0,
      accentColorValue:
          (colors['accentColorValue'] as int?)?.toDouble() ??
          (json['accentColorValue'] as int?)?.toDouble() ??
          0xFFFFD56A,
      effectColorValue:
          (colors['effectColorValue'] as int?)?.toDouble() ??
          (json['effectColorValue'] as int?)?.toDouble() ??
          0xFFF1C40F,
      infoPanelTitleColorValue:
          (colors['infoPanelTitleColorValue'] as int?)?.toDouble() ??
          (json['infoPanelTitleColorValue'] as int?)?.toDouble() ??
          0xFF3949AB,
      panelSpacing:
          (layout['panelSpacing'] as num?)?.toDouble() ??
          (json['panelSpacing'] as num?)?.toDouble() ??
          8.0,
      clockHorizontalPadding:
          (layout['clockHorizontalPadding'] as num?)?.toDouble() ??
          (json['clockHorizontalPadding'] as num?)?.toDouble() ??
          30.0,
      containerMargin:
          (layout['containerMargin'] as num?)?.toDouble() ??
          (json['containerMargin'] as num?)?.toDouble() ??
          16.0,
      containerPadding:
          (layout['containerPadding'] as num?)?.toDouble() ??
          (json['containerPadding'] as num?)?.toDouble() ??
          8.0,
      highlightStrokeWidth:
          (colors['highlightStrokeWidth'] as num?)?.toDouble() ??
          (json['highlightStrokeWidth'] as num?)?.toDouble() ??
          6.0,
      outlineWidth:
          (colors['outlineWidth'] as num?)?.toDouble() ??
          (json['outlineWidth'] as num?)?.toDouble() ??
          2.0,
      smallDialWidth:
          (smallDial['width'] as num?)?.toDouble() ??
          (json['smallDialWidth'] as num?)?.toDouble() ??
          176.0,
      smallDialHeight:
          (smallDial['height'] as num?)?.toDouble() ??
          (json['smallDialHeight'] as num?)?.toDouble() ??
          210.0,
      responsive: ResponsiveUiConfig.fromJson(responsive),
    );
  }

  MainDialMode get mainDialModeEnum => mainDialMode == 'hexagrams'
      ? MainDialMode.hexagrams
      : MainDialMode.timeFlow;

  Set<ClockDialRing> get visibleRingsSet =>
      visibleRings.map(_parseRing).toSet();

  static ClockDialRing _parseRing(String name) {
    return ClockDialRing.values.firstWhere(
      (r) => r.name == name,
      orElse: () => ClockDialRing.months,
    );
  }
}

class ResponsiveUiConfig {
  final double breakpoint;
  final String mobileLayout;
  final double mobileMainDialMinSize;
  final double mobileMainDialMaxSize;
  final bool mobileMainDialAutoHeight;
  final double mobileMainDialRadiusFactor;
  final double mobileMainDialCaptionFontSize;
  final double mobileZoomMinScale;
  final double mobileZoomMaxScale;
  final double mobileZoomStep;
  final double mobileZoomBaseScale;
  final double mobileHorizontalInset;
  final List<String> mobileHiddenRings;
  final double mobileHourRingFontSize;
  final double mobileCurrentHourRingFontSize;
  final double mobileRotatingGeneralFontSize;
  final double mobileRotatingBranchFontSize;
  final double mobileHexagramFontScale;
  final double mobileProtectionRayReachFactor;
  final bool mobileReverseSections;
  final bool mobileInfoPanelAutoHeight;
  final bool mobileShowPanelToggleButtons;
  final String mobileToolbarPlacement;
  final String mobileModeSwitchPlacement;
  final bool mobileShowScrollbar;
  final int mobileToolbarColumns;
  final String desktopLayout;
  final double desktopPanelWidth;
  final double desktopMainDialBaseSize;
  final double desktopMainDialScaleFactor;
  final double desktopZoomMinScale;
  final double desktopZoomMaxScale;
  final double desktopZoomStep;
  final double desktopInfoPanelHeight;
  final bool desktopShowPanelToggleButtons;
  final String desktopToolbarPlacement;
  final String desktopModeSwitchPlacement;
  final bool desktopShowScrollbar;
  final int desktopToolbarColumns;

  const ResponsiveUiConfig({
    this.breakpoint = 700,
    this.mobileLayout = 'singleColumn',
    this.mobileMainDialMinSize = 240,
    this.mobileMainDialMaxSize = 540,
    this.mobileMainDialAutoHeight = true,
    this.mobileMainDialRadiusFactor = 0.96,
    this.mobileMainDialCaptionFontSize = 16,
    this.mobileZoomMinScale = 0.9,
    this.mobileZoomMaxScale = 1.4,
    this.mobileZoomStep = 0.1,
    this.mobileZoomBaseScale = 1.4,
    this.mobileHorizontalInset = 32,
    this.mobileHiddenRings = const [
      'months',
      'weeks',
      'days',
      'seconds',
      'meridians',
    ],
    this.mobileHourRingFontSize = 12,
    this.mobileCurrentHourRingFontSize = 14,
    this.mobileRotatingGeneralFontSize = 12,
    this.mobileRotatingBranchFontSize = 8,
    this.mobileHexagramFontScale = 0.72,
    this.mobileProtectionRayReachFactor = 3,
    this.mobileReverseSections = true,
    this.mobileInfoPanelAutoHeight = true,
    this.mobileShowPanelToggleButtons = false,
    this.mobileToolbarPlacement = 'aboveMainDial',
    this.mobileModeSwitchPlacement = 'aboveMainDial',
    this.mobileShowScrollbar = false,
    this.mobileToolbarColumns = 6,
    this.desktopLayout = 'threeColumn',
    this.desktopPanelWidth = 206,
    this.desktopMainDialBaseSize = 60,
    this.desktopMainDialScaleFactor = 540,
    this.desktopZoomMinScale = 0.9,
    this.desktopZoomMaxScale = 1.6,
    this.desktopZoomStep = 0.1,
    this.desktopInfoPanelHeight = 912,
    this.desktopShowPanelToggleButtons = true,
    this.desktopToolbarPlacement = 'overlay',
    this.desktopModeSwitchPlacement = 'overlay',
    this.desktopShowScrollbar = true,
    this.desktopToolbarColumns = 4,
  });

  factory ResponsiveUiConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ResponsiveUiConfig();
    final mobile = json['mobile'] as Map<String, dynamic>? ?? {};
    final desktop = json['desktop'] as Map<String, dynamic>? ?? {};
    return ResponsiveUiConfig(
      breakpoint: (json['breakpoint'] as num?)?.toDouble() ?? 700,
      mobileLayout: mobile['layout'] as String? ?? 'singleColumn',
      mobileMainDialMinSize:
          (mobile['mainDialMinSize'] as num?)?.toDouble() ?? 240,
      mobileMainDialMaxSize:
          (mobile['mainDialMaxSize'] as num?)?.toDouble() ?? 540,
      mobileMainDialAutoHeight: mobile['mainDialAutoHeight'] as bool? ?? true,
      mobileMainDialRadiusFactor:
          (mobile['mainDialRadiusFactor'] as num?)?.toDouble() ?? 0.96,
      mobileMainDialCaptionFontSize:
          (mobile['mainDialCaptionFontSize'] as num?)?.toDouble() ?? 16,
      mobileZoomMinScale: (mobile['zoomMinScale'] as num?)?.toDouble() ?? 0.9,
      mobileZoomMaxScale: (mobile['zoomMaxScale'] as num?)?.toDouble() ?? 1.4,
      mobileZoomStep: (mobile['zoomStep'] as num?)?.toDouble() ?? 0.1,
      mobileZoomBaseScale: (mobile['zoomBaseScale'] as num?)?.toDouble() ?? 1.4,
      mobileHorizontalInset:
          (mobile['horizontalInset'] as num?)?.toDouble() ?? 32,
      mobileHiddenRings:
          (mobile['hiddenRings'] as List?)?.cast<String>() ??
          const ['months', 'weeks', 'days', 'seconds', 'meridians'],
      mobileHourRingFontSize:
          (mobile['hourRingFontSize'] as num?)?.toDouble() ?? 12,
      mobileCurrentHourRingFontSize:
          (mobile['currentHourRingFontSize'] as num?)?.toDouble() ?? 14,
      mobileRotatingGeneralFontSize:
          (mobile['rotatingGeneralFontSize'] as num?)?.toDouble() ?? 12,
      mobileRotatingBranchFontSize:
          (mobile['rotatingBranchFontSize'] as num?)?.toDouble() ?? 8,
      mobileHexagramFontScale:
          (mobile['hexagramFontScale'] as num?)?.toDouble() ?? 0.72,
      mobileProtectionRayReachFactor:
          (mobile['protectionRayReachFactor'] as num?)?.toDouble() ?? 3,
      mobileReverseSections: mobile['reverseSections'] as bool? ?? true,
      mobileInfoPanelAutoHeight: mobile['infoPanelAutoHeight'] as bool? ?? true,
      mobileShowPanelToggleButtons:
          mobile['showPanelToggleButtons'] as bool? ?? false,
      mobileToolbarPlacement:
          mobile['toolbarPlacement'] as String? ?? 'aboveMainDial',
      mobileModeSwitchPlacement:
          mobile['modeSwitchPlacement'] as String? ?? 'aboveMainDial',
      mobileShowScrollbar: mobile['showScrollbar'] as bool? ?? false,
      mobileToolbarColumns: mobile['toolbarColumns'] as int? ?? 6,
      desktopLayout: desktop['layout'] as String? ?? 'threeColumn',
      desktopPanelWidth: (desktop['panelWidth'] as num?)?.toDouble() ?? 206,
      desktopMainDialBaseSize:
          (desktop['mainDialBaseSize'] as num?)?.toDouble() ?? 60,
      desktopMainDialScaleFactor:
          (desktop['mainDialScaleFactor'] as num?)?.toDouble() ?? 540,
      desktopZoomMinScale: (desktop['zoomMinScale'] as num?)?.toDouble() ?? 0.9,
      desktopZoomMaxScale: (desktop['zoomMaxScale'] as num?)?.toDouble() ?? 1.6,
      desktopZoomStep: (desktop['zoomStep'] as num?)?.toDouble() ?? 0.1,
      desktopInfoPanelHeight:
          (desktop['infoPanelHeight'] as num?)?.toDouble() ?? 912,
      desktopShowPanelToggleButtons:
          desktop['showPanelToggleButtons'] as bool? ?? true,
      desktopToolbarPlacement:
          desktop['toolbarPlacement'] as String? ?? 'overlay',
      desktopModeSwitchPlacement:
          desktop['modeSwitchPlacement'] as String? ?? 'overlay',
      desktopShowScrollbar: desktop['showScrollbar'] as bool? ?? true,
      desktopToolbarColumns: desktop['toolbarColumns'] as int? ?? 4,
    );
  }

  Set<ClockDialRing> get mobileHiddenRingSet => ClockDialRing.values
      .where((ring) => mobileHiddenRings.contains(ring.name))
      .toSet();
}

/// 主题配置数据模型
class AppThemeConfig {
  final String id;
  final String name;
  final String preset;
  final String mode;
  final String seedColor;
  final String brightness;
  final bool useMaterial3;
  final UiConfig ui;

  AppThemeConfig({
    required this.id,
    required this.name,
    required this.preset,
    required this.mode,
    required this.seedColor,
    required this.brightness,
    required this.useMaterial3,
    required this.ui,
  });

  /// 从 JSON Map 构造
  factory AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      preset: json['preset'] as String,
      mode: json['mode'] as String,
      seedColor: json['seedColor'] as String,
      brightness: json['brightness'] as String,
      useMaterial3: json['useMaterial3'] as bool? ?? true,
      ui: UiConfig.fromJson(json['ui'] as Map<String, dynamic>?),
    );
  }

  /// 转换为 ThemeMode
  ThemeMode get themeMode => mode == 'dark' ? ThemeMode.dark : ThemeMode.light;

  bool get isMobileOptimized => preset == 'mobileOptimized';

  /// 转换为Brightness
  Brightness get brightnessEnum =>
      brightness == 'dark' ? Brightness.dark : Brightness.light;

  /// 解析 16 进制颜色
  Color get color {
    final hex = seedColor.replaceAll('#', '');
    return Color(0xFF000000 | int.parse(hex, radix: 16));
  }

  /// 生成Flutter的ThemeData
  ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightnessEnum,
    ),
    useMaterial3: useMaterial3,
  );
}

/// 主题管理器：加载和管理所有主题
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  List<AppThemeConfig> _themes = [];
  int _currentIndex = 0;

  List<AppThemeConfig> get themes => _themes;
  AppThemeConfig get currentTheme => _themes[_currentIndex];

  /// 从 assets 加载主题配置
  Future<void> loadThemes() async {
    if (_themes.isNotEmpty) return;
    final jsonStr = await rootBundle.loadString('assets/themes.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = data['themes'] as List<dynamic>;
    _themes = list
        .map((e) => AppThemeConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 切换主题
  void setTheme(int index) {
    _currentIndex = index;
  }

  bool setThemeById(String id) {
    final index = _themes.indexWhere((theme) => theme.id == id);
    if (index < 0) return false;
    _currentIndex = index;
    return true;
  }

  /// 根据 ID 查找主题
  AppThemeConfig? findById(String id) {
    try {
      return _themes.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
