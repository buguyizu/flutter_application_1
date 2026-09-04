import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'clock_models.dart';
import 'clock_painter.dart';
import 'clock_toolbar.dart';
import 'dial_geometry.dart';
import 'dial_painters.dart';
import 'small_dial_column.dart';

part 'small_dial_widgets.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.themeOption,
    required this.onThemeOptionChanged,
  });

  final DisplayLanguage language;
  final ValueChanged<DisplayLanguage> onLanguageChanged;
  final AppThemeOption themeOption;
  final ValueChanged<AppThemeOption> onThemeOptionChanged;

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  static const String _appVersion = '1.0.1+1';

  // 皇极经世纪年锚点：日甲一元、月子一会、星甲一运、辰子一世。
  static const int _historicalEraStartYear = -67046;
  // 连续六十甲子基准：天文纪年4年为甲子年。
  static const int _sexagenaryCycleBaseYear = 4;
  static const int _yearsPerShi = 30;
  static const int _yearsPerYun = 12 * _yearsPerShi;
  static const int _yearsPerHui = 30 * _yearsPerYun;

  late DateTime _now;
  Timer? _timer;
  int? _hoveredYearIndex;
  int? _hoveredBranchIndex;
  int? _hoveredYunIndex;
  int? _hoveredShiIndex;
  ClockDialRing? _hoveredClockRing;
  Offset? _clockTooltipPosition;
  double _clockScale = 1.3;
  bool _leftDialColumnCollapsed = false;
  bool _protectionExpanded = false;
  late DisplayLanguage _language;
  final Set<ClockDialRing> _visibleClockRings = Set.of(ClockDialRing.values);
  late final AnimationController _branchNumberRotationController;
  late final ScrollController _horizontalScrollController;

  DateTime _chinaNow() {
    return DateTime.now();
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
      setState(() {
        _now = _chinaNow();
      });
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
    final double clockContainerSize = 60 + 540 * _clockScale;
    final double clockVerticalOffset = max(
      0.0,
      (leftDialColumnHeight - clockContainerSize) / 2,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1.2,
                    ),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                key: const ValueKey('left_panel_container'),
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                width: 206,
                                alignment: Alignment.centerLeft,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: _leftDialColumnCollapsed ? 0 : 1,
                                  curve: Curves.easeInOut,
                                  child: IgnorePointer(
                                    ignoring: _leftDialColumnCollapsed,
                                    child: SizedBox(
                                      width: 206,
                                      child: SmallDialColumn(
                                        children: [
                                          _buildPlaceholderBranchDial(_now),
                                          const SizedBox(height: 24),
                                          _buildThirtySegmentDial(_now),
                                          const SizedBox(height: 24),
                                          _buildTwelveSegmentDial(
                                            _huangjiShiIndex(_now),
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
                            padding: EdgeInsets.only(top: clockVerticalOffset),
                            child: SizedBox(
                              width: clockContainerSize,
                              height: clockContainerSize + 80,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                ),
                                child: SizedBox(
                                  width: clockContainerSize,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox.square(
                                        dimension: clockContainerSize,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.help,
                                              onExit: (_) => setState(() {
                                                _hoveredClockRing = null;
                                                _clockTooltipPosition = null;
                                              }),
                                              onHover: (event) {
                                                final ring = _clockRingAt(
                                                  event.localPosition,
                                                  constraints.biggest,
                                                );
                                                if (ring != _hoveredClockRing ||
                                                    event.localPosition !=
                                                        _clockTooltipPosition) {
                                                  setState(() {
                                                    _hoveredClockRing = ring;
                                                    _clockTooltipPosition =
                                                        event.localPosition;
                                                  });
                                                }
                                              },
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapUp: (details) {
                                                  final ring = _clockRingAt(
                                                    details.localPosition,
                                                    constraints.biggest,
                                                  );
                                                  if (ring ==
                                                          ClockDialRing
                                                              .branchNumbers ||
                                                      ring ==
                                                          ClockDialRing
                                                              .branches) {
                                                    _branchNumberRotationController
                                                        .forward(from: 0);
                                                  }
                                                },
                                                child: _buildClockCanvas(
                                                  constraints,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        _formatTime(_now),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 206,
                            height: leftDialColumnHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _localized(
                                                  '时间旋流',
                                                  'Time Flow',
                                                  '時間の流転',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PopupMenuButton<
                                                  DisplayLanguage
                                                >(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  iconSize: 22,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 176,
                                                      ),
                                                  tooltip: _localized(
                                                    '切换语言',
                                                    'Change language',
                                                    '言語を切り替え',
                                                  ),
                                                  icon: const Icon(
                                                    Icons.language,
                                                  ),
                                                  onSelected: (language) {
                                                    setState(
                                                      () =>
                                                          _language = language,
                                                    );
                                                    widget.onLanguageChanged(
                                                      language,
                                                    );
                                                  },
                                                  itemBuilder: (context) => [
                                                    CheckedPopupMenuItem(
                                                      value: DisplayLanguage
                                                          .chinese,
                                                      checked:
                                                          _language ==
                                                          DisplayLanguage
                                                              .chinese,
                                                      child: const Text('简体中文'),
                                                    ),
                                                    CheckedPopupMenuItem(
                                                      value: DisplayLanguage
                                                          .traditionalChinese,
                                                      checked:
                                                          _language ==
                                                          DisplayLanguage
                                                              .traditionalChinese,
                                                      child: const Text('繁體中文'),
                                                    ),
                                                    CheckedPopupMenuItem(
                                                      value: DisplayLanguage
                                                          .english,
                                                      checked:
                                                          _language ==
                                                          DisplayLanguage
                                                              .english,
                                                      child: const Text(
                                                        'English',
                                                      ),
                                                    ),
                                                    CheckedPopupMenuItem(
                                                      value: DisplayLanguage
                                                          .japanese,
                                                      checked:
                                                          _language ==
                                                          DisplayLanguage
                                                              .japanese,
                                                      child: const Text('日本語'),
                                                    ),
                                                  ],
                                                ),
                                                PopupMenuButton<AppThemeOption>(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  iconSize: 22,
                                                  tooltip: _localized(
                                                    '选择主题',
                                                    'Choose theme',
                                                    'テーマを選択',
                                                    traditionalChinese: '選擇主題',
                                                  ),
                                                  icon: const Icon(
                                                    Icons.palette_outlined,
                                                  ),
                                                  onSelected: widget
                                                      .onThemeOptionChanged,
                                                  itemBuilder: (context) => AppThemeOption
                                                      .values
                                                      .map(
                                                        (
                                                          themeOption,
                                                        ) => CheckedPopupMenuItem<AppThemeOption>(
                                                          value: themeOption,
                                                          checked:
                                                              widget
                                                                  .themeOption ==
                                                              themeOption,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 12,
                                                                height: 12,
                                                                decoration: BoxDecoration(
                                                                  color: themeOption
                                                                      .preset
                                                                      .seedColor,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                _themeOptionLabel(
                                                                  themeOption,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'v$_appVersion',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          _localized(
                                            '元会运世',
                                            'Yuan Hui Yun Shi',
                                            '元会運世',
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _localized(
                                            '以《皇极经世》中的方式记录时间旋流，一元为129600年。\n一元含十二会，\n一会含三十运，\n一运含十二世，\n一世为三十年。\n当前日甲一元范围：\n公元前67046年~公元62553年',
                                            'Time flows according to the Huangji Jingshi cycle. One yuan is 129,600 years.\nOne yuan contains twelve hui,\none hui contains thirty yun,\none yun contains twelve shi,\none shi contains thirty years.\nCurrent Yuan 1:\n67046 BCE - 62553 CE',
                                            '『皇極経世』に基づき時間の流転を記録します。一元は129,600年です。\n一元は十二会、\n一会は三十運、\n一運は十二世、\n一世は三十年です。\n現在の日甲一元の範囲：\n紀元前67046年〜西暦62553年',
                                          ),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        if (_protectionExpanded)
                                          Text(
                                            _localized(
                                              '大将守护',
                                              'General Protection',
                                              '大将の守護',
                                            ),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (_protectionExpanded) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _localized(
                                              '十二药叉大将源自于唐三藏法师玄奘所译《药师琉璃光如来本愿功德经》，发愿卫护饶益流布此经及受持此如来名号之一切有情众生。在旋流守护时，请持续恭敬念诵：\n南无药师琉璃光如来！\n\n也可以依次恭敬念诵十二药叉大将的名号：\n官毗罗大将\n伐折罗大将\n迷企罗大将\n安底罗大将\n頞你罗大将\n珊底罗大将\n因达罗大将\n披夷罗大将\n摩虎罗大将\n真达罗大将\n招杜罗大将\n毗羯罗大将',
                                              'The Twelve Yaksha Generals are described in the Bhaiṣajyaguru Vaidūryaprabharāja Sūtra translated by Xuanzang. During the rotation, respectfully recite:\nNamo Bhaiṣajyaguru Vaidūryaprabharāja Tathāgata!\n\nThe Twelve Yaksha Generals:\nKumbhira\nVajra\nMihira\nAndira\nAnila\nSandila\nIndra\nPajra\nMahoraga\nCandala\nCatura\nVikala',
                                              '十二薬叉大将は、玄奘訳『薬師瑠璃光如来本願功徳経』に説かれます。旋流守護の間、敬意をもって念誦してください。\n南無薬師瑠璃光如来！\n\n十二薬叉大将：\n官毗罗大将\n伐折罗大将\n迷企罗大将\n安底罗大将\n頞你罗大将\n珊底罗大将\n因达罗大将\n披夷罗大将\n摩虎罗大将\n真达罗大将\n招杜罗大将\n毗羯罗大将',
                                            ),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontSize: 13,
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: _buildUnifiedLeftToolbar(context),
                                  ),
                                ),
                              ],
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

  Widget _buildUnifiedLeftToolbar(BuildContext context) {
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
          width: 44,
          height: 44,
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
                fixedSize: const Size.square(44),
                padding: const EdgeInsets.all(4),
                shape: buttonShape,
              ),
              icon: icon,
            ),
          ),
        ),
      );
    }

    return ClockToolbar(
      children: [
        _buildClockScaleButton(
          context,
          icon: Icons.add,
          tooltip: _localized('放大大盘', 'Zoom in', '大盤を拡大'),
          onPressed: _clockScale >= 1.8 ? null : () => _changeClockScale(0.1),
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
          onPressed: _clockScale <= 0.7 ? null : () => _changeClockScale(-0.1),
        ),
        buildActionButton(
          Icon(
            _protectionExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          _protectionExpanded
              ? _localized(
                  '收起大将守护',
                  'Collapse General Protection',
                  '大将の守護を折りたたむ',
                )
              : _localized('展开大将守护', 'Expand General Protection', '大将の守護を展開'),
          () => setState(() {
            _protectionExpanded = !_protectionExpanded;
          }),
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
        const SizedBox.shrink(),
      ],
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
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              fixedSize: const Size.square(44),
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
          width: 44,
          height: 44,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
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

  void _changeClockScale(double delta) {
    setState(() {
      _clockScale = (_clockScale + delta).clamp(0.9, 1.6);
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

  String _themePresetLabel(AppThemePreset themePreset) {
    return switch (themePreset) {
      AppThemePreset.chronicleIndigo => _localized(
        '时序靛',
        'Chronicle Indigo',
        '時序藍',
        traditionalChinese: '時序靛',
      ),
      AppThemePreset.jingshiJade => _localized(
        '经世青',
        'Jingshi Jade',
        '経世緑',
        traditionalChinese: '經世青',
      ),
      AppThemePreset.moonPhaseGold => _localized(
        '月相金',
        'Moon Phase Gold',
        '月相金',
      ),
      AppThemePreset.cinnabarRed => _localized(
        '朱砂红',
        'Cinnabar Red',
        '朱砂赤',
        traditionalChinese: '朱砂紅',
      ),
      AppThemePreset.midnightInk => _localized(
        '子夜墨',
        'Midnight Ink',
        '真夜中の墨',
        traditionalChinese: '子夜墨',
      ),
      AppThemePreset.bambooShade => _localized(
        '幽篁青',
        'Bamboo Shade',
        '幽篁の緑',
        traditionalChinese: '幽篁青',
      ),
    };
  }

  String _themeOptionLabel(AppThemeOption themeOption) {
    final brightnessLabel = themeOption.themeMode == ThemeMode.dark
        ? _localized('深色', 'Dark', 'ダーク', traditionalChinese: '深色')
        : _localized('亮色', 'Light', 'ライト', traditionalChinese: '亮色');
    return '${_themePresetLabel(themeOption.preset)} $brightnessLabel';
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
    final number = _huangjiHuiNumber(time);
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
    final number = _huangjiYunNumberForYear(year);
    return _localized(
      '星${_heavenlyStem(number - 1)}$number运',
      'Yun $number',
      '星${_heavenlyStem(number - 1)}$number運',
    );
  }

  String _shiLabel(int year) {
    final time = DateTime(year);
    final number = _huangjiShiNumber(time);
    return _localized(
      '辰${_earthlyBranch(_huangjiShiIndex(time))}$number世',
      'Shi $number',
      '辰${_earthlyBranch(_huangjiShiIndex(time))}$number世',
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

  // ignore: unused_element
  Widget _legacyBuildPlaceholderBranchDial(DateTime time) {
    final huiIndex = _huangjiHuiIndex(time);
    final huiLabel = _huiLabel(time);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredBranchIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 12);
          if (index != _hoveredBranchIndex) {
            setState(() => _hoveredBranchIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: BranchPlaceholderPainter(
                  _localized('日甲一元', 'Yuan 1', '日甲一元'),
                  huiIndex,
                  subtitle: huiLabel,
                  language: _language,
                  hoveredIndex: _hoveredBranchIndex,
                  hoverLabel: _hoveredBranchIndex == null
                      ? null
                      : _huiLabelForNumber(
                          _huangjiHuiNumber(time) +
                              (_hoveredBranchIndex! - huiIndex),
                        ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
                  children: [
                    TextSpan(
                      text: _localized('日甲一元', 'Yuan 1', '日甲一元'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（12会-129600年）',
                        ' (12 Hui - 129,600 years)',
                        '（12会・129,600年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _legacyBuildThirtySegmentDial(DateTime time) {
    final currentIndex = _huangjiYunIndex(time);
    final huiLabel = _huiLabel(time);
    final firstYunNumber = _huangjiYunNumber(time) - currentIndex;
    final yunLabel = _yunLabel(time.year);
    final hoverLabel = _hoveredYunIndex == null
        ? null
        : _yunLabelForNumber(firstYunNumber + _hoveredYunIndex!);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredYunIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 30);
          if (index != _hoveredYunIndex) {
            setState(() => _hoveredYunIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: ThirtySegmentDialPainter(
                  currentIndex,
                  title: huiLabel,
                  labels: List<String>.generate(
                    30,
                    (index) => '${firstYunNumber + index}',
                  ),
                  labelIndices: List<int>.generate(30, (index) => index),
                  startAtBottom: true,
                  hoveredIndex: _hoveredYunIndex,
                  hoverLabel: hoverLabel,
                  currentLabel: yunLabel,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
                  children: [
                    TextSpan(
                      text: huiLabel,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（30运-10800年）',
                        ' (30 Yun - 10,800 years)',
                        '（30運・10,800年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _yunLabelForNumber(int number) {
    return _localized(
      '星${_heavenlyStem(number - 1)}$number运',
      'Yun $number',
      '星${_heavenlyStem(number - 1)}$number運',
    );
  }

  // ignore: unused_element
  Widget _legacyBuildTwelveSegmentDial(int currentIndex, int year) {
    final startYear = _yearCycleStart(year);
    return SizedBox(
      width: 176,
      height: 210,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoveredShiIndex = null),
        onHover: (event) {
          final index = dialIndexAt(event.localPosition, 12);
          if (index != _hoveredShiIndex) {
            setState(() => _hoveredShiIndex = index);
          }
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: TwelveSegmentDialPainter(
                  currentIndex,
                  startYear,
                  language: _language,
                  title: _yunLabel(year),
                  subtitle: _shiLabel(year),
                  hoveredIndex: _hoveredShiIndex,
                  hoverLabel: _hoveredShiIndex == null
                      ? null
                      : _shiLabel(
                          year +
                              (_hoveredShiIndex! - currentIndex) * _yearsPerShi,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF37474F),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: _yunLabel(year),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _localized(
                        '（12世-360年）',
                        ' (12 Shi - 360 years)',
                        '（12世・360年）',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ClockDialRing? _clockRingAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 10;
    final hourRadius = outerRadius * 0.86;
    final secondsCenter = center + Offset(0, -hourRadius * 0.22);
    final secondsRadius = hourRadius * 0.15;
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
      final ringDistance = (distance - ring.radiusFor(outerRadius)).abs();
      if (ringDistance <= ring.hitTolerance && ringDistance < closestDistance) {
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

  int _huangjiHuiIndex(DateTime time) {
    return (_huangjiHuiNumber(time) - 1).remainder(12);
  }

  int _huangjiShiIndex(DateTime time) {
    return (_huangjiShiNumber(time) - 1).remainder(12);
  }

  int _yearCycleStart(int year) {
    return _historicalEraStartYear +
        (year - _historicalEraStartYear) ~/ _yearsPerShi * _yearsPerShi;
  }

  int _huangjiYunIndex(DateTime time) {
    return (_huangjiYunNumber(time) - 1).remainder(30);
  }

  int _huangjiHuiNumber(DateTime time) {
    return (time.year - _historicalEraStartYear) ~/ _yearsPerHui + 1;
  }

  int _huangjiYunNumber(DateTime time) {
    return _huangjiYunNumberForYear(time.year);
  }

  int _huangjiYunNumberForYear(int year) {
    return (year - _historicalEraStartYear) ~/ _yearsPerYun + 1;
  }

  int _huangjiShiNumber(DateTime time) {
    return (time.year - _historicalEraStartYear) ~/ _yearsPerShi + 1;
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
