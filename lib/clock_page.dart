import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'clock_painter.dart';
import 'dial_painters.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  // 皇极经世历史纪年锚点：1024年固定为“丑”，每30年顺移一世支。
  static const int _historicalEraStartYear = 1024;
  static const int _historicalEraStartBranchNumber = 2;

  late DateTime _now;
  Timer? _timer;
  int? _hoveredYearIndex;
  ClockDialRing? _hoveredClockRing;
  Offset? _clockTooltipPosition;
  double _clockScale = 1.3;
  late final AnimationController _branchNumberRotationController;
  late final ScrollController _horizontalScrollController;

  DateTime _chinaNow() {
    // 固定使用中国标准时间 UTC+08:00，避免受本机时区影响。
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26, width: 1.2),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPlaceholderBranchDial(
                              '会',
                              _huangjiHuiIndex(_now),
                            ),
                            const SizedBox(height: 24),
                            _buildThirtySegmentDial(_huangjiYunIndex(_now)),
                            const SizedBox(height: 24),
                            _buildTwelveSegmentDial(
                              _huangjiShiIndex(_now),
                              _now.year,
                            ),
                            const SizedBox(height: 24),
                            _buildYearDial(_now),
                          ],
                        ),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 60 + 540 * _clockScale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned(
                                  left: 64,
                                  bottom: 0,
                                  right: 0,
                                  child: Text(
                                    _formatTime(_now),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
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
                                            behavior: HitTestBehavior.opaque,
                                            onTapUp: (details) {
                                              final ring = _clockRingAt(
                                                details.localPosition,
                                                constraints.biggest,
                                              );
                                              if (ring ==
                                                      ClockDialRing
                                                          .branchNumbers ||
                                                  ring ==
                                                      ClockDialRing.branches) {
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
                                ),
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  child: _buildClockScaleControls(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 176,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '时间旋流',
                                    style: TextStyle(
                                      color: Color(0xFF283593),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    '元会运世',
                                    style: TextStyle(
                                      color: Color(0xFF37474F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '以《皇极经世》中的方式记录时间旋流：\n一元含十二会，\n一会含三十运，\n一运含十二世，\n一世为三十年。\n一元总为129600天。',
                                    style: TextStyle(
                                      color: Color(0xFF546E7A),
                                      fontSize: 13,
                                      height: 1.6,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Divider(color: Colors.black12),
                                  SizedBox(height: 20),
                                  Text(
                                    '大将守护',
                                    style: TextStyle(
                                      color: Color(0xFF37474F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '十二药叉大将源自于唐三藏法师玄奘所译《药师琉璃光如来本愿功德经》，发愿卫护饶益流布此经及受持此如来名号之一切有情。在旋流守护时，请持续恭敬念诵：\n南无药师琉璃光如来！\n\n也可以依次恭敬念诵十二药叉大将的名号：\n官毗罗大将\n伐折罗大将\n迷企罗大将\n安底罗大将\n頞你罗大将\n珊底罗大将\n因达罗大将\n披夷罗大将\n摩虎罗大将\n真达罗大将\n招杜罗大将\n毗羯罗大将',
                                    style: TextStyle(
                                      color: Color(0xFF546E7A),
                                      fontSize: 13,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: Tooltip(
                                  message: '启动一轮旋流守护',
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _branchNumberRotationController
                                            .isAnimating
                                        ? null
                                        : () => _branchNumberRotationController
                                              .forward(from: 0),
                                    icon: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.diagonal3Values(
                                        -1,
                                        1,
                                        1,
                                      ),
                                      child: Icon(Icons.autorenew),
                                    ),
                                    label: const Text('旋流守护'),
                                  ),
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

  Widget _buildClockScaleControls() {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 3,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '放大大盘',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _clockScale >= 1.8
                  ? null
                  : () => _changeClockScale(0.1),
            ),
          ),
          const Divider(height: 1),
          Tooltip(
            message: '缩小大盘',
            child: IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _clockScale <= 0.7
                  ? null
                  : () => _changeClockScale(-0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _changeClockScale(double delta) {
    setState(() {
      _clockScale = (_clockScale + delta).clamp(0.9, 1.6);
    });
  }

  Widget _buildPlaceholderBranchDial(String label, int currentIndex) {
    return SizedBox(
      width: 176,
      height: 210,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: BranchPlaceholderPainter(
                label == '会' ? '日甲一元' : label,
                currentIndex % 12,
                subtitle: label == '会' ? '月午七会' : null,
              ),
            ),
          ),
          if (label == '会' || label == '世')
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
                  children: label == '会'
                      ? [
                          const TextSpan(
                            text: '日甲一元',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '（12会-129600年）'),
                        ]
                      : [const TextSpan(text: '一世为30年')],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThirtySegmentDial(int currentIndex) {
    return SizedBox(
      width: 176,
      height: 210,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: ThirtySegmentDialPainter(
                currentIndex,
                title: '月午七会',
                labels: List<String>.generate(30, (index) => '${index + 181}'),
                labelIndices: List<int>.generate(30, (index) => index),
                startAtBottom: true,
                currentLabel: '星乙192运',
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
                children: [
                  TextSpan(
                    text: '月午七会',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '（30运-10800年）'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwelveSegmentDial(int currentIndex, int year) {
    final startYear = _yearCycleStart(year);
    return SizedBox(
      width: 176,
      height: 210,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: TwelveSegmentDialPainter(currentIndex, startYear),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Color(0xFF37474F), fontSize: 12),
                children: [
                  TextSpan(
                    text: '星乙192运',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '（12世-360年）'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDial(DateTime time) {
    final startYear = _yearCycleStart(time.year);
    final yearLabels = List<String>.generate(
      30,
      (index) => '${startYear + index}',
    );
    return MouseRegion(
      onExit: (_) => setState(() => _hoveredYearIndex = null),
      onHover: (event) {
        final index = _yearIndexAt(event.localPosition);
        if (index != _hoveredYearIndex) {
          setState(() => _hoveredYearIndex = index);
        }
      },
      child: SizedBox(
        width: 176,
        height: 210,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(
                painter: ThirtySegmentDialPainter(
                  time.year - startYear,
                  title: '辰戌2303世',
                  labels: yearLabels,
                  labelIndices: List<int>.generate(30, (index) => index),
                  startAtBottom: true,
                  rotateLabels: true,
                  titleFontSize: 19,
                  currentLabelOffsetY: 12,
                  hoveredIndex: _hoveredYearIndex,
                  hoverLabel: _hoveredYearIndex == null
                      ? null
                      : '${startYear + _hoveredYearIndex!}年（${_sexagenaryYear(startYear + _hoveredYearIndex!)}年）',
                  currentLabel: '${time.year}年（${_sexagenaryYear(time.year)}年）',
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
                    const TextSpan(
                      text: '辰戌2303世',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '（30年）'),
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

  int? _yearIndexAt(Offset position) {
    const center = Offset(88, 122);
    final delta = position - center;
    if (delta.distance > 88) {
      return null;
    }
    const step = 2 * pi / 30;
    const startAngle = pi / 2 - step / 2;
    var angle = atan2(delta.dy, delta.dx);
    var relativeAngle = (angle - startAngle) % (2 * pi);
    if (relativeAngle < 0) relativeAngle += 2 * pi;
    return (relativeAngle / step).floor().clamp(0, 29);
  }

  ClockDialRing? _clockRingAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (position - center).distance;
    final outerRadius = size.shortestSide / 2 - 10;
    ClockDialRing? closestRing;
    var closestDistance = double.infinity;

    for (final ring in ClockDialRing.values) {
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
      ClockDialRing.months => '月份圈',
      ClockDialRing.weeks => '周数圈',
      ClockDialRing.days => '年天数圈',
      ClockDialRing.hours => '24小时圈',
      ClockDialRing.branchNumbers => '大将守护圈，点击启动【旋流守护】。',
      ClockDialRing.branches => '地支时辰圈',
      ClockDialRing.meridians => '经络圈',
      ClockDialRing.minutes => '分钟圈',
    };
  }

  int _huangjiHuiIndex(DateTime time) {
    return 6;
  }

  int _huangjiShiIndex(DateTime time) {
    final eraIndex = (time.year - _historicalEraStartYear) ~/ 30;
    // 地支按1开始编号：1=子，2=丑，……，11=戌，12=亥。
    final branchNumber =
        ((_historicalEraStartBranchNumber - 1 + eraIndex) % 12) + 1;
    // 绘图数组从0开始，因此将1基序号转换为数组索引。
    return branchNumber - 1;
  }

  int _yearCycleStart(int year) {
    return _historicalEraStartYear +
        (year - _historicalEraStartYear) ~/ 30 * 30;
  }

  int _huangjiYunIndex(DateTime time) {
    return 192 - 181;
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
    final cycleIndex = (year - 1984) % 60;
    return '${heavenlyStems[cycleIndex % 10]}${earthlyBranches[cycleIndex % 12]}';
  }

  String _formatTime(DateTime time) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    final currentWeek = ((dayOfYear - time.weekday + 10) / 7).floor().clamp(
      1,
      52,
    );
    return '${time.year}年（${_sexagenaryYear(time.year)}年）'
        '第$currentWeek周${twoDigits(time.month)}月${twoDigits(time.day)}日 '
        '${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}';
  }
}
