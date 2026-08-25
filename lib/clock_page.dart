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

class _ClockPageState extends State<ClockPage> {
  // 皇极经世历史纪年锚点：1024年固定为“丑”，每30年顺移一世支。
  static const int _historicalEraStartYear = 1024;
  static const int _historicalEraStartBranchNumber = 2;

  late DateTime _now;
  Timer? _timer;
  int? _hoveredYearIndex;

  DateTime _chinaNow() {
    // 固定使用中国标准时间 UTC+08:00，避免受本机时区影响。
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  @override
  void initState() {
    super.initState();
    _now = _chinaNow();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = _chinaNow();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 840,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26, width: 1.2),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlaceholderBranchDial(
                            '会',
                            _huangjiHuiIndex(_now),
                          ),
                          const SizedBox(width: 24),
                          _buildThirtySegmentDial(_huangjiYunIndex(_now)),
                          const SizedBox(width: 24),
                          _buildTwelveSegmentDial(
                            _huangjiShiIndex(_now),
                            _now.year,
                          ),
                          const SizedBox(width: 24),
                          _buildYearDial(_now),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _formatTime(_now),
                        textAlign: TextAlign.center,
                        softWrap: false,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: ClockPainter(_now),
                          size: const Size.square(200),
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
    );
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
