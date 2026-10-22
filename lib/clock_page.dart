import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/clock_models.dart';
import 'models/clock_calculations.dart';
import 'models/theme_model.dart';
import 'clock_painter.dart';
import 'widgets/clock_toolbar.dart';
import 'widgets/clock_header_actions.dart';
import 'widgets/dial_geometry.dart';
import 'dial_painters.dart';
import 'widgets/small_dial_column.dart';

part 'widgets/small_dial_widgets.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.theme,
    required this.themes,
    required this.onThemeChanged,
  });

  final DisplayLanguage language;
  final ValueChanged<DisplayLanguage> onLanguageChanged;
  final AppThemeConfig theme;
  final List<AppThemeConfig> themes;
  final ValueChanged<String> onThemeChanged;

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  // 连续六十甲子基准：天文纪年4年为甲子年。
  static const int _sexagenaryCycleBaseYear = 4;

  late DateTime _now;
  int? _selectedYear;
  Timer? _timer;
  int? _hoveredYearIndex;
  int? _hoveredBranchIndex;
  int? _hoveredYunIndex;
  int? _hoveredShiIndex;
  int? _hoveredHexagramIndex;
  bool _isFirstDialHovered = false;
  bool _isSecondDialHovered = false;
  ClockDialRing? _hoveredClockRing;
  Offset? _clockTooltipPosition;
  double _clockScale = 1.3;
  bool _leftDialColumnCollapsed = false;
  bool _yuanHuiExpanded = true;
  bool _branchMeridianExpanded = true;
  bool _protectionExpanded = false;
  bool _rightInfoColumnCollapsed = false;
  MainDialMode _mainDialMode = MainDialMode.timeFlow;
  MainDialMode get _activeMainDialMode =>
      _isFirstDialHovered || _isSecondDialHovered
      ? MainDialMode.hexagrams
      : _mainDialMode;
  double _hexagramRotation = 0;
  Offset? _hexagramDragPosition;
  late DisplayLanguage _language;
  final Set<ClockDialRing> _visibleClockRings = Set.of(ClockDialRing.values);
  bool? _lastAppliedMobileRingDefaults;
  String? _lastAppliedRingThemeId;
  late final AnimationController _branchNumberRotationController;
  late final ScrollController _horizontalScrollController;

  double get _smallDialWidthVal => widget.theme.ui.smallDialWidth;
  double get _smallDialHeightVal => widget.theme.ui.smallDialHeight;
  Color get _subtitleTextColor =>
      Color(widget.theme.ui.subtitleColorValue.toInt());
  double get _subtitleFontSizeVal => widget.theme.ui.subtitleFontSize;
  FontWeight get _subtitleFontWeight => FontWeight.values.firstWhere(
    (fontWeight) =>
        fontWeight.value == widget.theme.ui.subtitleFontWeight.toInt(),
    orElse: () => FontWeight.bold,
  );

  DateTime _chinaNow() => DateTime.now();

  void _applyDefaultVisibleRings() {
    final responsive = widget.theme.ui.responsive;
    final isMobile =
        MediaQuery.sizeOf(context).width < responsive.breakpoint &&
        responsive.mobileLayout == 'singleColumn';
    if (_lastAppliedMobileRingDefaults == isMobile &&
        _lastAppliedRingThemeId == widget.theme.id) {
      return;
    }

    _lastAppliedMobileRingDefaults = isMobile;
    _lastAppliedRingThemeId = widget.theme.id;
    _visibleClockRings
      ..clear()
      ..addAll(ClockDialRing.values);
    if (isMobile) {
      _visibleClockRings.removeAll(responsive.mobileHiddenRingSet);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyDefaultVisibleRings();
  }

  @override
  void didUpdateWidget(covariant ClockPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.id != widget.theme.id) {
      _applyDefaultVisibleRings();
    }
  }

  @override
  void initState() {
    super.initState();
    _language = widget.language;
    _now = _chinaNow();
    _horizontalScrollController = ScrollController();
    _branchNumberRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() => setState(() {}));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentTime = _chinaNow();
      setState(() {
        _now = _selectedYear == null
            ? currentTime
            : _dateWithYear(currentTime, _selectedYear!);
      });
    });
  }

  DateTime _dateWithYear(DateTime date, int year) {
    final lastDayOfMonth = DateTime(year, date.month + 1, 0).day;
    return DateTime(
      year,
      date.month,
      min(date.day, lastDayOfMonth),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  void _restoreCurrentTime() {
    if (_selectedYear == null) {
      return;
    }
    setState(() {
      _selectedYear = null;
      _now = _chinaNow();
      _hoveredYearIndex = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _horizontalScrollController.dispose();
    _branchNumberRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double leftDialColumnHeight = 4 * 210 + 3 * 24;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final responsive = widget.theme.ui.responsive;
    final isMobile =
        viewportWidth < responsive.breakpoint &&
        responsive.mobileLayout == 'singleColumn';
    final mobileAvailableDialSize = max(
      0.0,
      viewportWidth - responsive.mobileHorizontalInset,
    );
    final mobileDialLimit = min(
      responsive.mobileMainDialMaxSize,
      mobileAvailableDialSize,
    );
    final mobileDialMinimum = min(
      responsive.mobileMainDialMinSize,
      mobileDialLimit,
    );
    final mobileScaledDialSize =
        mobileDialLimit * (_clockScale / responsive.mobileZoomBaseScale);
    final double clockContainerSize = isMobile
        ? min(mobileDialLimit, max(mobileDialMinimum, mobileScaledDialSize))
        : responsive.desktopMainDialBaseSize +
              responsive.desktopMainDialScaleFactor * _clockScale;
    final zoomMinScale = isMobile
        ? responsive.mobileZoomMinScale
        : responsive.desktopZoomMinScale;
    final zoomMaxScale = isMobile
        ? responsive.mobileZoomMaxScale
        : responsive.desktopZoomMaxScale;
    final zoomStep = isMobile
        ? responsive.mobileZoomStep
        : responsive.desktopZoomStep;
    final canZoomIn = isMobile
        ? _clockScale < zoomMaxScale &&
              clockContainerSize < mobileDialLimit - 0.5
        : _clockScale < zoomMaxScale;
    final canZoomOut = isMobile
        ? _clockScale > zoomMinScale &&
              clockContainerSize > mobileDialMinimum + 0.5
        : _clockScale > zoomMinScale;
    final bool useMobileLayout = isMobile;
    final double clockVerticalOffset = useMobileLayout
        ? 0
        : max(0.0, (leftDialColumnHeight - clockContainerSize) / 2);
    final double rightPanelWidth = useMobileLayout
        ? viewportWidth - responsive.mobileHorizontalInset
        : responsive.desktopPanelWidth;
    final bool singleColumn = useMobileLayout;
    final bool infoPanelAutoHeight =
        singleColumn && responsive.mobileInfoPanelAutoHeight;
    final bool showScrollbar = singleColumn
        ? responsive.mobileShowScrollbar
        : responsive.desktopShowScrollbar;
    final bool threeColumnLayout =
        !singleColumn && responsive.desktopLayout == 'threeColumn';
    final displayThemes = widget.themes
        .where((theme) => theme.isMobileOptimized == isMobile)
        .toList(growable: false);
    final modeSwitchPlacement = useMobileLayout
        ? responsive.mobileModeSwitchPlacement
        : responsive.desktopModeSwitchPlacement;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if ((event.buttons & kSecondaryMouseButton) != 0) {
            _restoreCurrentTime();
          }
        },
        child: SafeArea(
          child: Center(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: showScrollbar,
              trackVisibility: showScrollbar,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: threeColumnLayout
                    ? Axis.horizontal
                    : Axis.vertical,
                child: Center(
                  child: Container(
                    width: singleColumn ? viewportWidth : null,
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    child: Scrollbar(
                      notificationPredicate: (notification) =>
                          !singleColumn && notification.depth == 0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SingleChildScrollView(
                            physics: singleColumn
                                ? const NeverScrollableScrollPhysics()
                                : null,
                            child: Flex(
                              direction: threeColumnLayout
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              crossAxisAlignment: singleColumn
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              verticalDirection:
                                  singleColumn &&
                                      responsive.mobileReverseSections
                                  ? VerticalDirection.up
                                  : VerticalDirection.down,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      key: const ValueKey(
                                        'left_panel_container',
                                      ),
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeInOut,
                                      width: singleColumn
                                          ? rightPanelWidth
                                          : responsive.desktopPanelWidth,
                                      alignment: singleColumn
                                          ? Alignment.center
                                          : Alignment.centerLeft,
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity: _leftDialColumnCollapsed
                                            ? 0
                                            : 1,
                                        curve: Curves.easeInOut,
                                        child: IgnorePointer(
                                          ignoring: _leftDialColumnCollapsed,
                                          child: SizedBox(
                                            width: responsive.desktopPanelWidth,
                                            child: SmallDialColumn(
                                              children: [
                                                _buildPlaceholderBranchDial(
                                                  _now,
                                                ),
                                                const SizedBox(height: 24),
                                                _buildThirtySegmentDial(_now),
                                                const SizedBox(height: 24),
                                                _buildTwelveSegmentDial(
                                                  ClockCalculations.shiIndex(
                                                    _now,
                                                  ),
                                                  _now.year,
                                                ),
                                                const SizedBox(height: 24),
                                                _buildYearDial(_now),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.zero,
                                  child: SizedBox(
                                    width:
                                        clockContainerSize +
                                        (singleColumn
                                            ? 0
                                            : responsive
                                                  .desktopMainDialBaseSize),
                                    height:
                                        singleColumn &&
                                            responsive.mobileMainDialAutoHeight
                                        ? null
                                        : clockContainerSize +
                                              clockVerticalOffset +
                                              80,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: singleColumn
                                            ? 0
                                            : widget
                                                  .theme
                                                  .ui
                                                  .clockHorizontalPadding,
                                      ),
                                      child: SizedBox(
                                        width: clockContainerSize,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            if (singleColumn &&
                                                modeSwitchPlacement ==
                                                    'aboveMainDial')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: _buildMainDialTabs(
                                                  context,
                                                  width: clockContainerSize,
                                                ),
                                              ),
                                            SizedBox(
                                              width: clockContainerSize,
                                              height:
                                                  clockContainerSize +
                                                  clockVerticalOffset,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Positioned(
                                                    top: clockVerticalOffset,
                                                    left: 0,
                                                    child: SizedBox.square(
                                                      key: const ValueKey(
                                                        'main_dial_face',
                                                      ),
                                                      dimension:
                                                          clockContainerSize,
                                                      child: LayoutBuilder(
                                                        builder: (context, constraints) {
                                                          return MouseRegion(
                                                            cursor:
                                                                SystemMouseCursors
                                                                    .help,
                                                            onExit: (_) => setState(() {
                                                              _hoveredClockRing =
                                                                  null;
                                                              _clockTooltipPosition =
                                                                  null;
                                                              _hoveredHexagramIndex =
                                                                  null;
                                                            }),
                                                            onHover: (event) {
                                                              if (_activeMainDialMode ==
                                                                  MainDialMode
                                                                      .hexagrams) {
                                                                final index = HexagramDialPlaceholderPainter.hexagramIndexAt(
                                                                  event
                                                                      .localPosition,
                                                                  constraints
                                                                      .biggest,
                                                                  rotation:
                                                                      _hexagramRotation,
                                                                );
                                                                if (index !=
                                                                    _hoveredHexagramIndex) {
                                                                  setState(() {
                                                                    _hoveredHexagramIndex =
                                                                        index;
                                                                  });
                                                                }
                                                                return;
                                                              }
                                                              if (_hoveredHexagramIndex !=
                                                                  null) {
                                                                setState(() {
                                                                  _hoveredHexagramIndex =
                                                                      null;
                                                                });
                                                              }
                                                              if (_activeMainDialMode !=
                                                                  MainDialMode
                                                                      .timeFlow) {
                                                                return;
                                                              }
                                                              final ring =
                                                                  _clockRingAt(
                                                                    event
                                                                        .localPosition,
                                                                    constraints
                                                                        .biggest,
                                                                  );
                                                              if (ring !=
                                                                      _hoveredClockRing ||
                                                                  event.localPosition !=
                                                                      _clockTooltipPosition) {
                                                                setState(() {
                                                                  _hoveredClockRing =
                                                                      ring;
                                                                  _clockTooltipPosition =
                                                                      event
                                                                          .localPosition;
                                                                });
                                                              }
                                                            },
                                                            child: GestureDetector(
                                                              behavior:
                                                                  HitTestBehavior
                                                                      .opaque,
                                                              onPanStart: (details) {
                                                                if (_activeMainDialMode ==
                                                                    MainDialMode
                                                                        .hexagrams) {
                                                                  _hexagramDragPosition =
                                                                      details
                                                                          .localPosition;
                                                                }
                                                              },
                                                              onPanUpdate: (details) {
                                                                if (_activeMainDialMode !=
                                                                        MainDialMode
                                                                            .hexagrams ||
                                                                    _hexagramDragPosition ==
                                                                        null) {
                                                                  return;
                                                                }
                                                                final center = Offset(
                                                                  constraints
                                                                          .maxWidth /
                                                                      2,
                                                                  constraints
                                                                          .maxHeight /
                                                                      2,
                                                                );
                                                                final previous =
                                                                    _hexagramDragPosition! -
                                                                    center;
                                                                final current =
                                                                    details
                                                                        .localPosition -
                                                                    center;
                                                                if (previous.distance >
                                                                        0 &&
                                                                    current.distance >
                                                                        0) {
                                                                  final previousAngle =
                                                                      atan2(
                                                                        previous
                                                                            .dy,
                                                                        previous
                                                                            .dx,
                                                                      );
                                                                  final currentAngle =
                                                                      atan2(
                                                                        current
                                                                            .dy,
                                                                        current
                                                                            .dx,
                                                                      );
                                                                  var delta =
                                                                      currentAngle -
                                                                      previousAngle;
                                                                  if (delta >
                                                                      pi) {
                                                                    delta -=
                                                                        2 * pi;
                                                                  } else if (delta <
                                                                      -pi) {
                                                                    delta +=
                                                                        2 * pi;
                                                                  }
                                                                  setState(() {
                                                                    _hexagramRotation +=
                                                                        delta;
                                                                    _hexagramDragPosition =
                                                                        details
                                                                            .localPosition;
                                                                  });
                                                                }
                                                              },
                                                              onPanEnd: (_) =>
                                                                  _hexagramDragPosition =
                                                                      null,
                                                              onSecondaryTap: () {
                                                                if (_activeMainDialMode ==
                                                                    MainDialMode
                                                                        .hexagrams) {
                                                                  setState(
                                                                    () =>
                                                                        _hexagramRotation =
                                                                            0,
                                                                  );
                                                                }
                                                              },
                                                              onTapUp: (details) {
                                                                if (_activeMainDialMode !=
                                                                    MainDialMode
                                                                        .timeFlow) {
                                                                  return;
                                                                }
                                                                final ring =
                                                                    _clockRingAt(
                                                                      details
                                                                          .localPosition,
                                                                      constraints
                                                                          .biggest,
                                                                    );
                                                                if (ring ==
                                                                        ClockDialRing
                                                                            .branchNumbers ||
                                                                    ring ==
                                                                        ClockDialRing
                                                                            .branches) {
                                                                  _branchNumberRotationController
                                                                      .forward(
                                                                        from: 0,
                                                                      );
                                                                }
                                                              },
                                                              child:
                                                                  _buildActiveDialCanvas(
                                                                    constraints,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  if (!singleColumn &&
                                                      modeSwitchPlacement ==
                                                          'overlay')
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: _buildMainDialTabs(
                                                        context,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  _activeMainDialMode ==
                                                      MainDialMode.hexagrams
                                                  ? 8
                                                  : 18,
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final isTimeFlowMode =
                                                    _activeMainDialMode ==
                                                    MainDialMode.timeFlow;
                                                return Text(
                                                  key: const ValueKey(
                                                    'main_dial_caption',
                                                  ),
                                                  isTimeFlowMode
                                                      ? _formatTime(_now)
                                                      : _hexagramDialSummary(
                                                          _now,
                                                        ),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: isTimeFlowMode
                                                        ? singleColumn
                                                              ? responsive
                                                                    .mobileMainDialCaptionFontSize
                                                              : 22
                                                        : 12,
                                                    fontWeight: isTimeFlowMode
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isTimeFlowMode
                                                        ? Colors.indigo
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                    height: isTimeFlowMode
                                                        ? null
                                                        : 1.1,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (singleColumn &&
                                    responsive.mobileToolbarPlacement ==
                                        'aboveMainDial')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: _buildRightToolbar(
                                      context,
                                      showPanelToggleButtons: responsive
                                          .mobileShowPanelToggleButtons,
                                      toolbarColumns:
                                          responsive.mobileToolbarColumns,
                                      toolbarWidth: rightPanelWidth,
                                      canZoomIn: canZoomIn,
                                      canZoomOut: canZoomOut,
                                      zoomStep: zoomStep,
                                      zoomMinScale: zoomMinScale,
                                      zoomMaxScale: zoomMaxScale,
                                    ),
                                  ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: rightPanelWidth,
                                    height: infoPanelAutoHeight
                                        ? null
                                        : responsive.desktopInfoPanelHeight,
                                    decoration: const BoxDecoration(),
                                    clipBehavior: Clip.hardEdge,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      opacity: _rightInfoColumnCollapsed
                                          ? 0
                                          : 1,
                                      child: IgnorePointer(
                                        ignoring: _rightInfoColumnCollapsed,
                                        child: SizedBox(
                                          width: rightPanelWidth,
                                          height: infoPanelAutoHeight
                                              ? null
                                              : responsive
                                                    .desktopInfoPanelHeight,
                                          child: Column(
                                            mainAxisSize: infoPanelAutoHeight
                                                ? MainAxisSize.min
                                                : MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                fit: infoPanelAutoHeight
                                                    ? FlexFit.loose
                                                    : FlexFit.tight,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              _localized(
                                                                '时间旋流',
                                                                'Time Flow',
                                                                '時間の流転',
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.primary,
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          ClockHeaderActions(
                                                            language: _language,
                                                            themeId:
                                                                widget.theme.id,
                                                            themes:
                                                                displayThemes,
                                                            onLanguageSelected:
                                                                (language) {
                                                                  setState(
                                                                    () => _language =
                                                                        language,
                                                                  );
                                                                  widget
                                                                      .onLanguageChanged(
                                                                        language,
                                                                      );
                                                                },
                                                            onThemeSelected: widget
                                                                .onThemeChanged,
                                                            languageTooltip:
                                                                _localized(
                                                                  '切换语言',
                                                                  'Change language',
                                                                  '言語を切り替え',
                                                                ),
                                                            themeTooltip: _localized(
                                                              '选择主题',
                                                              'Choose theme',
                                                              'テーマを選択',
                                                              traditionalChinese:
                                                                  '選擇主題',
                                                            ),
                                                            themeLabel:
                                                                _themeOptionLabel,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      InkWell(
                                                        onTap: () => setState(
                                                          () => _yuanHuiExpanded =
                                                              !_yuanHuiExpanded,
                                                        ),
                                                        child: SizedBox(
                                                          width:
                                                              rightPanelWidth,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .circle,
                                                                      size: 6,
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        _localized(
                                                                          '元会运世',
                                                                          'Yuan Hui Yun Shi',
                                                                          '元会運世',
                                                                        ),
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).colorScheme.onSurface,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Icon(
                                                                _yuanHuiExpanded
                                                                    ? Icons
                                                                          .expand_less
                                                                    : Icons
                                                                          .expand_more,
                                                                size: 20,
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (_yuanHuiExpanded) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          _localized(
                                                            '以《皇极经世》中的方式记录时间旋流，一元为129600年。\n一元含十二会，\n一会含三十运，\n一运含十二世，\n一世为三十年。\n当前日甲一元范围：\n公元前67046年~公元62553年',
                                                            'Time flows according to the Huangji Jingshi cycle. One yuan is 129,600 years.\nOne yuan contains twelve hui,\none hui contains thirty yun,\none yun contains twelve shi,\none shi contains thirty years.\nCurrent Yuan 1:\n67046 BCE - 62553 CE',
                                                            '『皇極経世』に基づき時間の流転を記録します。一元は129,600年です。\n一元は十二会、\n一会は三十運、\n一運は十二世、\n一世は三十年です。\n現在の日甲一元の範囲：\n紀元前67046年〜西暦62553年',
                                                          ),
                                                          style: TextStyle(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 13,
                                                            height: 1.6,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      InkWell(
                                                        onTap: () => setState(
                                                          () => _branchMeridianExpanded =
                                                              !_branchMeridianExpanded,
                                                        ),
                                                        child: SizedBox(
                                                          width:
                                                              rightPanelWidth,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .circle,
                                                                      size: 6,
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        _localized(
                                                                          '地支经络',
                                                                          'Earthly Branches and Meridians',
                                                                          '地支と経絡',
                                                                        ),
                                                                        softWrap:
                                                                            true,
                                                                        maxLines:
                                                                            2,
                                                                        style: TextStyle(
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).colorScheme.onSurface,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Icon(
                                                                _branchMeridianExpanded
                                                                    ? Icons
                                                                          .expand_less
                                                                    : Icons
                                                                          .expand_more,
                                                                size: 20,
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (_branchMeridianExpanded) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          _localized(
                                                            '地支时辰圈以十二地支划分昼夜时辰，经络圈对应十二时辰的经络运行节律。两圈由同一时刻同步旋转，展示时辰与经络的对应关系。',
                                                            'The earthly-branch ring divides the day into twelve double-hours. The meridian ring shows the meridian rhythm associated with those periods. Both rings rotate with the same time reference.',
                                                            '地支時辰の環は十二地支で一日を十二の時辰に分け、経絡の環は各時辰に対応する経絡のリズムを示します。両方の環は同じ時刻を基準に連動します。',
                                                          ),
                                                          style: TextStyle(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 13,
                                                            height: 1.6,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      InkWell(
                                                        onTap: () => setState(
                                                          () => _protectionExpanded =
                                                              !_protectionExpanded,
                                                        ),
                                                        child: SizedBox(
                                                          width:
                                                              rightPanelWidth,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .circle,
                                                                      size: 6,
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        _localized(
                                                                          '大将守护',
                                                                          'General Protection',
                                                                          '大将の守護',
                                                                        ),
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).colorScheme.onSurface,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Icon(
                                                                _protectionExpanded
                                                                    ? Icons
                                                                          .expand_less
                                                                    : Icons
                                                                          .expand_more,
                                                                size: 20,
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (_protectionExpanded) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          _localized(
                                                            '十二药叉大将源自于唐三藏法师玄奘所译《药师琉璃光如来本愿功德经》，发愿卫护饶益流布此经及受持此如来名号之一切有情众生。在旋流守护时，请持续恭敬念诵：\n南无药师琉璃光如来！\n\n也可以依次恭敬念诵十二药叉大将的名号：\n官毗罗大将\n伐折罗大将\n迷企罗大将\n安底罗大将\n頞你罗大将\n珊底罗大将\n因达罗大将\n披夷罗大将\n摩虎罗大将\n真达罗大将\n招杜罗大将\n毗羯罗大将',
                                                            'The Twelve Yaksha Generals are described in the Bhaiṣajyaguru Vaidūryaprabharāja Sūtra translated by Xuanzang. During the rotation, respectfully recite:\nNamo Bhaiṣajyaguru Vaidūryaprabharāja Tathāgata!\n\nThe Twelve Yaksha Generals:\nKumbhira\nVajra\nMihira\nAndira\nAnila\nSandila\nIndra\nPajra\nMahoraga\nCandala\nCatura\nVikala',
                                                            '十二薬叉大将は、玄奘訳『薬師瑠璃光如来本願功徳経』に説かれます。旋流守護の間、敬意をもって念誦してください。\n南無薬師瑠璃光如来！\n\n十二薬叉大将：\n官毗罗大将\n伐折罗大将\n迷企罗大将\n安底罗大将\n頞你罗大将\n珊底罗大将\n因达罗大将\n披夷罗大将\n摩虎罗大将\n真达罗大将\n招杜罗大将\n毗羯罗大将',
                                                          ),
                                                          style: TextStyle(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 13,
                                                            height: 1.6,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.circle,
                                                            size: 6,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            _localized(
                                                              '信息',
                                                              'Information',
                                                              '情報',
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurface,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        _localized(
                                                          '时间旋流是一个以时间为轴，探索元会运世、地支时辰与经络对应关系的 Flutter 示例工程。',
                                                          'Time Flow is a Flutter sample project exploring the relationships between Yuan Hui Yun Shi, earthly branches, and meridians through time.',
                                                          '時間旋流は、時間を軸に元会運世、地支時辰、経絡の対応関係を探る Flutter サンプルプロジェクトです。',
                                                        ),
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                          fontSize: 13,
                                                          height: 1.6,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      InkWell(
                                                        onTap: () => launchUrl(
                                                          Uri.parse(
                                                            'https://github.com/buguyizu/flutter_application_1',
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '${_localized('工程目录：', 'Project: ', 'プロジェクト：')}GitHub',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                            fontSize: 13,
                                                            height: 1.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!singleColumn &&
                              responsive.desktopToolbarPlacement == 'overlay')
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: _buildRightToolbar(
                                context,
                                showPanelToggleButtons:
                                    responsive.desktopShowPanelToggleButtons,
                                toolbarColumns:
                                    responsive.desktopToolbarColumns,
                                canZoomIn: canZoomIn,
                                canZoomOut: canZoomOut,
                                zoomStep: zoomStep,
                                zoomMinScale: zoomMinScale,
                                zoomMaxScale: zoomMaxScale,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClockCanvas(BoxConstraints constraints) {
    final responsive = widget.theme.ui.responsive;
    final isMobile =
        MediaQuery.sizeOf(context).width < responsive.breakpoint &&
        responsive.mobileLayout == 'singleColumn';
    final hourBaseFactor = isMobile
        ? responsive.mobileMainDialRadiusFactor
        : ClockRadiusFactors.hourBase;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: ClockPainter(
            _now,
            hoveredRing: _hoveredClockRing,
            visibleRings: Set<ClockDialRing>.unmodifiable(_visibleClockRings),
            language: _language,
            colorScheme: Theme.of(context).colorScheme,
            isBranchNumbersRotating:
                _branchNumberRotationController.isAnimating,
            branchNumbersRotation:
                _branchNumberRotationController.value * 2 * pi,
            hourRingFontSize: isMobile ? responsive.mobileHourRingFontSize : 20,
            currentHourRingFontSize: isMobile
                ? responsive.mobileCurrentHourRingFontSize
                : 22,
            rotatingGeneralFontSize: isMobile
                ? responsive.mobileRotatingGeneralFontSize
                : 16,
            rotatingBranchFontSize: isMobile
                ? responsive.mobileRotatingBranchFontSize
                : 12,
            hourBaseFactor: hourBaseFactor,
            protectionRayReachFactor: isMobile
                ? responsive.mobileProtectionRayReachFactor
                : 1.41421356237,
          ),
          size: const Size.square(200),
        ),
        if (_hoveredClockRing != null && _clockTooltipPosition != null)
          Positioned(
            left: (_clockTooltipPosition!.dx + 14).clamp(
              0.0,
              constraints.maxWidth - 116,
            ),
            top: (_clockTooltipPosition!.dy + 14).clamp(
              0.0,
              constraints.maxHeight - 32,
            ),
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF263238),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      _clockRingTooltip(_hoveredClockRing!),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveDialCanvas(BoxConstraints constraints) {
    if (_activeMainDialMode == MainDialMode.hexagrams) {
      final responsive = widget.theme.ui.responsive;
      final isMobile =
          MediaQuery.sizeOf(context).width < responsive.breakpoint &&
          responsive.mobileLayout == 'singleColumn';
      return CustomPaint(
        painter: HexagramDialPlaceholderPainter(
          colorScheme: Theme.of(context).colorScheme,
          rotation: _hexagramRotation,
          fontScale: isMobile ? responsive.mobileHexagramFontScale : 1,
          currentYear: _now.year,
          currentHuiIndex: ClockCalculations.huiIndex(_now),
          currentYunNumber: ClockCalculations.yunNumber(_now),
          currentYunIndex: ClockCalculations.yunIndex(_now),
          hoveredIndex: _hoveredHexagramIndex,
          showSovereignHuiLabels: _hoveredBranchIndex != null,
          showCurrentHuiYunNumbers: _isSecondDialHovered,
        ),
      );
    }
    return _buildClockCanvas(constraints);
  }

  Widget _buildRightToolbar(
    BuildContext context, {
    required bool showPanelToggleButtons,
    required int toolbarColumns,
    required bool canZoomIn,
    required bool canZoomOut,
    required double zoomStep,
    required double zoomMinScale,
    required double zoomMaxScale,
    double toolbarWidth = 166,
  }) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    Widget buildActionButton(
      Widget icon,
      String tooltipMessage,
      VoidCallback? onPressed, {
      Key? key,
      Color? backgroundColor,
      Color? foregroundColor,
    }) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Tooltip(
            message: tooltipMessage,
            child: IconButton(
              key: key,
              tooltip: tooltipMessage,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor:
                    backgroundColor ?? Theme.of(context).colorScheme.surface,
                foregroundColor:
                    foregroundColor ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
                fixedSize: const Size.square(32),
                padding: const EdgeInsets.all(4),
                shape: buttonShape,
              ),
              icon: icon,
            ),
          ),
        ),
      );
    }

    final buttons = <Widget>[
      _buildClockScaleButton(
        context,
        icon: Icons.add,
        tooltip: _localized('放大大盘', 'Zoom in', '大盤を拡大'),
        onPressed: canZoomIn
            ? () => _changeClockScale(
                zoomStep,
                minScale: zoomMinScale,
                maxScale: zoomMaxScale,
              )
            : null,
      ),
      buildActionButton(
        Icon(
          _leftDialColumnCollapsed ? Icons.chevron_right : Icons.chevron_left,
          size: 20,
        ),
        _leftDialColumnCollapsed
            ? _localized('展开左列', 'Expand left column', '左列を展開')
            : _localized('收起左列', 'Collapse left column', '左列を折りたたむ'),
        () => setState(() {
          _leftDialColumnCollapsed = !_leftDialColumnCollapsed;
        }),
        key: const ValueKey('toggle_left_panel_button'),
      ),
      _buildClockScaleButton(
        context,
        icon: Icons.remove,
        tooltip: _localized('缩小大盘', 'Zoom out', '大盤を縮小'),
        onPressed: canZoomOut
            ? () => _changeClockScale(
                -zoomStep,
                minScale: zoomMinScale,
                maxScale: zoomMaxScale,
              )
            : null,
      ),
      buildActionButton(
        Icon(
          _rightInfoColumnCollapsed ? Icons.chevron_left : Icons.chevron_right,
          size: 20,
        ),
        _rightInfoColumnCollapsed
            ? _localized('展开右列', 'Expand right column', '右列を展開')
            : _localized('收起右列', 'Collapse right column', '右列を折叠'),
        () => setState(() {
          _rightInfoColumnCollapsed = !_rightInfoColumnCollapsed;
        }),
        key: const ValueKey('toggle_right_panel_button'),
      ),
      _buildClockLayerButton(context),
      buildActionButton(
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(-1, 1, 1),
          child: const Icon(Icons.autorenew, size: 20),
        ),
        _localized('启动一轮旋流守护', 'Start one protection cycle', '旋流守護を開始'),
        _branchNumberRotationController.isAnimating
            ? null
            : () => _branchNumberRotationController.forward(from: 0),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      _buildClockScaleButton(
        context,
        icon: Icons.visibility,
        tooltip: _localized('显示全部圈层', 'Show all layers', 'すべての環を表示'),
        onPressed: _restoreAllClockRings,
      ),
      buildActionButton(
        const Icon(Icons.info_outline, size: 20),
        _localized('查看信息', 'View information', '情報を表示'),
        () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_localized('时间旋流', 'Time Flow', '時間旋流')),
            content: Text(
              _localized(
                '以时间为轴，展示元会运世、地支时辰与经络的对应关系。',
                'A time-based view of the relationships between Yuan Hui Yun Shi, earthly branches, and meridians.',
                '時間を軸に、元会運世、地支時辰、経絡の対応関係を表示します。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_localized('关闭', 'Close', '閉じる')),
              ),
            ],
          ),
        ),
      ),
    ];
    return ClockToolbar(
      crossAxisCount: toolbarColumns,
      width: toolbarWidth,
      children: [
        buttons[0],
        buttons[2],
        buttons[4],
        buttons[6],
        if (showPanelToggleButtons) buttons[1],
        if (showPanelToggleButtons) buttons[3],
        buttons[5],
        buttons[7],
      ],
    );
  }

  Widget _buildMainDialTabs(BuildContext context, {double width = 206}) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget buildTab(MainDialMode mode, String label) {
      final isActive = _activeMainDialMode == mode;
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isActive) {
              return;
            }
            setState(() {
              _mainDialMode = mode;
              _hoveredClockRing = null;
              _clockTooltipPosition = null;
              _hoveredHexagramIndex = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? inactiveColor : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? activeColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: buildTab(
              MainDialMode.timeFlow,
              _localized('日盘', 'Day dial', '日盤'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: buildTab(
              MainDialMode.hexagrams,
              _localized('卦盘', 'Hexagram dial', '卦盤'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockScaleButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              fixedSize: const Size.square(32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: Icon(icon),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildClockLayerButton(BuildContext context) {
    final tooltip = _localized('显示或隐藏圈层', 'Show or hide layers', '環を表示または非表示');
    return Tooltip(
      message: tooltip,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<ClockDialRing>(
              padding: EdgeInsets.zero,
              iconSize: 20,
              constraints: const BoxConstraints(minHeight: 40),
              tooltip: tooltip,
              icon: const Icon(Icons.layers_outlined),
              onSelected: _toggleClockRing,
              itemBuilder: (context) => ClockDialRing.values
                  .map(
                    (ring) => CheckedPopupMenuItem<ClockDialRing>(
                      value: ring,
                      checked: _visibleClockRings.contains(ring),
                      child: Text(_clockLayerLabel(ring)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _changeClockScale(
    double delta, {
    required double minScale,
    required double maxScale,
  }) {
    setState(() {
      _clockScale = (_clockScale + delta).clamp(minScale, maxScale);
    });
  }

  void _toggleClockRing(ClockDialRing ring) {
    setState(() {
      if (_visibleClockRings.contains(ring)) {
        _visibleClockRings.remove(ring);
        if (_hoveredClockRing == ring) {
          _hoveredClockRing = null;
          _clockTooltipPosition = null;
        }
      } else {
        _visibleClockRings.add(ring);
      }
    });
  }

  void _restoreAllClockRings() {
    setState(() => _visibleClockRings.addAll(ClockDialRing.values));
  }

  String _localized(
    String chinese,
    String english,
    String japanese, {
    String? traditionalChinese,
  }) {
    final text = switch (_language) {
      DisplayLanguage.chinese => chinese,
      DisplayLanguage.traditionalChinese => traditionalChinese ?? chinese,
      DisplayLanguage.english => english,
      DisplayLanguage.japanese => japanese,
    };
    return _language == DisplayLanguage.traditionalChinese
        ? _toTraditionalChinese(text)
        : text;
  }

  String _themePresetLabel(String themePreset) {
    return switch (themePreset) {
      'chronicleIndigo' => _localized(
        '时序靛',
        'Chronicle Indigo',
        '時序藍',
        traditionalChinese: '時序靛',
      ),
      'jingshiJade' => _localized(
        '经世青',
        'Jingshi Jade',
        '経世緑',
        traditionalChinese: '經世青',
      ),
      'moonPhaseGold' => _localized('月相金', 'Moon Phase Gold', '月相金'),
      'cinnabarRed' => _localized(
        '朱砂红',
        'Cinnabar Red',
        '朱砂赤',
        traditionalChinese: '朱砂紅',
      ),
      'midnightInk' => _localized(
        '子夜墨',
        'Midnight Ink',
        '真夜中の墨',
        traditionalChinese: '子夜墨',
      ),
      'bambooShade' => _localized(
        '幽篁青',
        'Bamboo Shade',
        '幽篁の緑',
        traditionalChinese: '幽篁青',
      ),
      _ => themePreset,
    };
  }

  String _themeOptionLabel(AppThemeConfig theme) {
    final brightnessLabel = theme.themeMode == ThemeMode.dark
        ? _localized('深色', 'Dark', 'ダーク', traditionalChinese: '深色')
        : _localized('亮色', 'Light', 'ライト', traditionalChinese: '亮色');
    return '${_themePresetLabel(theme.preset)} $brightnessLabel';
  }

  String _toTraditionalChinese(String text) {
    const replacements = <String, String>{
      '时间': '時間',
      '显示': '顯示',
      '隐藏': '隱藏',
      '主题': '主題',
      '语言': '語言',
      '切换': '切換',
      '经络': '經絡',
      '分钟': '分鐘',
      '小时': '小時',
      '年天数': '年天數',
      '周数': '週數',
      '地支时辰': '地支時辰',
      '大将': '大將',
      '皇极经世': '皇極經世',
      '记录': '記錄',
      '会': '會',
      '运': '運',
      '当前': '當前',
      '范围': '範圍',
      '药': '藥',
      '愿': '願',
      '发': '發',
      '卫': '衛',
      '护': '護',
      '饶': '饒',
      '经': '經',
      '众': '眾',
      '启动': '啟動',
      '一轮': '一輪',
      '缩': '縮',
    };
    for (final replacement in replacements.entries) {
      text = text.replaceAll(replacement.key, replacement.value);
    }
    return text;
  }

  String _huiLabel(DateTime time) {
    final number = ClockCalculations.huiNumber(time);
    return _huiLabelForNumber(number);
  }

  String _huiLabelForNumber(int number) {
    return _localized(
      '月${_earthlyBranch(number - 1)}$number会',
      'Hui $number',
      '月${_earthlyBranch(number - 1)}$number会',
    );
  }

  String _yunLabel(int year) {
    final number = ClockCalculations.yunNumberForYear(year);
    return _localized(
      '星${_heavenlyStem(number - 1)}$number运',
      'Yun $number',
      '星${_heavenlyStem(number - 1)}$number運',
    );
  }

  String _shiLabel(int year) {
    final time = DateTime(year);
    final number = ClockCalculations.shiNumber(time);
    return _localized(
      '辰${_earthlyBranch(ClockCalculations.shiIndex(time))}$number世',
      'Shi $number',
      '辰${_earthlyBranch(ClockCalculations.shiIndex(time))}$number世',
    );
  }

  String _yearLabel(int year) {
    final sexagenary = _sexagenaryYear(year);
    return _localized(
      '$year年（$sexagenary年）',
      '$year ($sexagenary)',
      '$year年（$sexagenary年）',
    );
  }

  String _yunLabelForNumber(int number) {
    return _localized(
      '星${_heavenlyStem(number - 1)}$number运',
      'Yun $number',
      '星${_heavenlyStem(number - 1)}$number運',
    );
  }

  String _hexagramDialSummary(DateTime time) {
    final huiNumber = ClockCalculations.huiNumber(time);
    final huiIndex = ClockCalculations.huiIndex(time);
    final yunNumber = ClockCalculations.yunNumber(time);
    final yunIndex = ClockCalculations.yunIndex(time);
    final huiHexagram =
        HexagramDialPlaceholderPainter.mainHexagramsByHuiIndex[huiIndex]!.first;
    final yunHexagram = HexagramDialPlaceholderPainter
        .mainHexagramsByHuiIndex[huiIndex]![yunIndex ~/ 6];
    final yearHexagram =
        HexagramDialPlaceholderPainter.hexagramForYear(time.year) ?? '*';
    final yearStemBranch = _sexagenaryYear(time.year);
    final huiBranch = _earthlyBranch(huiNumber - 1);
    final yunStem = _heavenlyStem(yunNumber - 1);
    final shiLabel = _shiLabel(time.year);

    return _localized(
      '日甲一元\n'
          '月$huiBranch$huiNumber会-$huiHexagram卦\n'
          '星$yunStem$yunNumber运-$yunHexagram卦\n'
          '$shiLabel-*卦\n'
          '${time.year}$yearStemBranch年-$yearHexagram卦',
      'Jia Yuan Day\n'
          'Hui $huiNumber - $huiHexagram Hexagram\n'
          'Yun $yunNumber - $yunHexagram Hexagram\n'
          '$shiLabel - * Hexagram\n'
          '${time.year} $yearStemBranch Year - $yearHexagram Hexagram',
      '日甲一元\n'
          '月$huiBranch$huiNumber会-$huiHexagram卦\n'
          '星$yunStem$yunNumber運-$yunHexagram卦\n'
          '$shiLabel-*卦\n'
          '${time.year}$yearStemBranch年-$yearHexagram卦',
    );
  }

  ClockDialRing? _clockRingAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 10;
    final responsive = widget.theme.ui.responsive;
    final isMobile =
        MediaQuery.sizeOf(context).width < responsive.breakpoint &&
        responsive.mobileLayout == 'singleColumn';
    final hourBaseFactor = isMobile
        ? responsive.mobileMainDialRadiusFactor
        : ClockRadiusFactors.hourBase;
    final hourRadius = outerRadius * hourBaseFactor;
    final secondsCenter =
        center +
        Offset(0, -hourRadius * ClockRadiusFactors.secondsVerticalOffset);
    final secondsRadius = hourRadius * ClockRadiusFactors.seconds;
    if (_visibleClockRings.contains(ClockDialRing.seconds) &&
        (position - secondsCenter).distance <= secondsRadius) {
      return ClockDialRing.seconds;
    }

    final distance = (position - center).distance;
    ClockDialRing? closestRing;
    var closestDistance = double.infinity;

    for (final ring in ClockDialRing.values) {
      if (ring == ClockDialRing.seconds || !_visibleClockRings.contains(ring)) {
        continue;
      }
      final hoverRadius = ring.hoverRadiusFor(
        outerRadius,
        hourBase: hourBaseFactor,
      );
      final ringDistance = (distance - hoverRadius).abs();
      final hitTolerance = max(
        ring.hitTolerance,
        ring.hoverWidthFor(outerRadius, hourBase: hourBaseFactor) / 2,
      );
      if (ringDistance <= hitTolerance && ringDistance < closestDistance) {
        closestRing = ring;
        closestDistance = ringDistance;
      }
    }
    return closestRing;
  }

  String _clockRingTooltip(ClockDialRing ring) {
    return switch (ring) {
      ClockDialRing.months => _localized('月份圈', 'Month ring', '月の環'),
      ClockDialRing.weeks => _localized('周数圈', 'Week ring', '週の環'),
      ClockDialRing.days => _localized('年天数圈', 'Day-of-year ring', '年日数の環'),
      ClockDialRing.hours => _localized('24小时圈', '24-hour ring', '24時間の環'),
      ClockDialRing.branchNumbers => _localized(
        '大将守护圈，点击启动【旋流守护】。',
        'General protection ring. Click to start rotation.',
        '大将守護の環。クリックして旋流守護を開始します。',
      ),
      ClockDialRing.branches => _localized(
        '地支时辰圈',
        'Earthly branch ring',
        '地支時辰の環',
      ),
      ClockDialRing.meridians => _localized('经络圈', 'Meridian ring', '経絡の環'),
      ClockDialRing.minutes => _localized('分钟圈', 'Minute ring', '分の環'),
      ClockDialRing.seconds => _localized('秒圈', 'Second ring', '秒の環'),
    };
  }

  String _clockLayerLabel(ClockDialRing ring) {
    return switch (ring) {
      ClockDialRing.months => _localized('月份', 'Months', '月'),
      ClockDialRing.weeks => _localized('周数', 'Weeks', '週'),
      ClockDialRing.days => _localized('年天数', 'Day of year', '年日数'),
      ClockDialRing.hours => _localized('24小时', '24 hours', '24時間'),
      ClockDialRing.branchNumbers => _localized('大将', 'Generals', '大将'),
      ClockDialRing.branches => _localized('地支时辰', 'Earthly branches', '地支時辰'),
      ClockDialRing.meridians => _localized('经络', 'Meridians', '経絡'),
      ClockDialRing.minutes => _localized('分钟', 'Minutes', '分'),
      ClockDialRing.seconds => _localized('秒圈', 'Seconds', '秒'),
    };
  }

  String _heavenlyStem(int index) {
    const heavenlyStems = <String>[
      '甲',
      '乙',
      '丙',
      '丁',
      '戊',
      '己',
      '庚',
      '辛',
      '壬',
      '癸',
    ];
    return heavenlyStems[index.remainder(heavenlyStems.length)];
  }

  String _earthlyBranch(int index) {
    const earthlyBranches = <String>[
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
    ];
    return earthlyBranches[index.remainder(earthlyBranches.length)];
  }

  String _sexagenaryYear(int year) {
    const heavenlyStems = <String>[
      '甲',
      '乙',
      '丙',
      '丁',
      '戊',
      '己',
      '庚',
      '辛',
      '壬',
      '癸',
    ];
    const earthlyBranches = <String>[
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
    ];
    const romanizedHeavenlyStems = <String>[
      'Jia',
      'Yi',
      'Bing',
      'Ding',
      'Wu',
      'Ji',
      'Geng',
      'Xin',
      'Ren',
      'Gui',
    ];
    const romanizedEarthlyBranches = <String>[
      'zi',
      'chou',
      'yin',
      'mao',
      'chen',
      'si',
      'wu',
      'wei',
      'shen',
      'you',
      'xu',
      'hai',
    ];
    final cycleIndex = ((year - _sexagenaryCycleBaseYear) % 60 + 60) % 60;
    if (_language == DisplayLanguage.english) {
      return '${romanizedHeavenlyStems[cycleIndex % 10]}${romanizedEarthlyBranches[cycleIndex % 12]}';
    }
    return '${heavenlyStems[cycleIndex % 10]}${earthlyBranches[cycleIndex % 12]}';
  }

  String _formatTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    final currentWeek = ((dayOfYear - time.weekday + 10) / 7).floor().clamp(
      1,
      52,
    );
    final date = '${twoDigits(time.month)}/${twoDigits(time.day)}';
    final clock =
        '${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}';
    return switch (_language) {
      DisplayLanguage.chinese =>
        '${time.year}年（${_sexagenaryYear(time.year)}年）'
            '第$currentWeek周${twoDigits(time.month)}月${twoDigits(time.day)}日 $clock',
      DisplayLanguage.traditionalChinese =>
        '${time.year}年（${_sexagenaryYear(time.year)}年）'
            '第$currentWeek週${twoDigits(time.month)}月${twoDigits(time.day)}日 $clock',
      DisplayLanguage.english =>
        '${_sexagenaryYear(time.year)} Year ${time.year} | Week $currentWeek | $date | $clock',
      DisplayLanguage.japanese =>
        '${time.year}年（${_sexagenaryYear(time.year)}年）'
            '第$currentWeek週${twoDigits(time.month)}月${twoDigits(time.day)}日 $clock',
    };
  }
}
