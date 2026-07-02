import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const ClockApp());
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '时钟',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ClockPage(),
    );
  }
}

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  late DateTime _now;
  Timer? _timer;

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
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE3F2FD),
                  border: Border.all(color: const Color(0xFF1E88E5), width: 3),
                ),
              ),
              const SizedBox(height: 10),
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
    );
  }

  String _formatTime(DateTime time) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    final currentWeek = ((dayOfYear - time.weekday + 10) / 7).floor().clamp(
      1,
      52,
    );
    return '${time.year}年第$currentWeek周${twoDigits(time.month)}月${twoDigits(time.day)}日 '
        '${twoDigits(time.hour)}:${twoDigits(time.minute)}:${twoDigits(time.second)}';
  }
}

class ClockPainter extends CustomPainter {
  ClockPainter(this.now);

  final DateTime now;
  final List<String> earthBranches = const [
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

  final List<String> meridians = const [
    '胆经',
    '肝经',
    '肺经',
    '大肠经',
    '胃经',
    '脾经',
    '心经',
    '小肠经',
    '膀胱经',
    '肾经',
    '心包经',
    '三焦经',
  ];

  final List<String> months = const [
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    // 重新规划半径，为外层腾出空间
    // 原来 radius 充满了几乎整个屏幕 (min(w,h)/2 - 10)
    // 现在我们要在这个空间里塞入更多层，所以内部的“大表盘”需要缩小
    double maxRadius = min(size.width, size.height) / 2 - 10;

    // 1. 最外层：月份圈
    _drawMonths(canvas, center, maxRadius);

    // 2. 年天数圈 - 位于月份圈内侧（365/366 天）
    double dayOfYearRadius = maxRadius * 0.955;
    _drawDaysOfYear(canvas, center, dayOfYearRadius);

    // 3. 周数圈 (一年52周) - 位于年天数圈内侧
    // 天数圈较薄，保留间距避免视觉重叠
    double weekRadius = maxRadius * 0.90;
    _drawWeeks(canvas, center, weekRadius);

    // 3. 24小时表盘 (原内容作为核心) - 位于月份圈内侧
    double hourRadius = maxRadius * 0.86;

    // 小秒盘跟随 hourRadius 调整
    final secondsCenter = center + Offset(0, -hourRadius * 0.22);
    final secondsRadius = hourRadius * 0.15;

    // 绘制层级 (从下到上)

    // 背景与外框 (基于 hourRadius)
    _drawDial(canvas, center, hourRadius);

    // 刻度与数字
    _drawTicks(canvas, center, hourRadius);
    _drawNumbers(canvas, center, hourRadius * 0.91);

    // 4. 地支
    _drawEarthBranches(canvas, center, hourRadius * 0.70);

    // 5. 经络
    _drawMeridians(canvas, center, hourRadius * 0.56);

    // 5.5 分钟圈（放在心经圈以内）
    _drawMiniteNumbers(canvas, center, hourRadius * 0.45);

    // 6. 小秒盘
    _drawSecondsDial(canvas, secondsCenter, secondsRadius);

    // 指针
    _drawHands(canvas, center, hourRadius, secondsCenter, secondsRadius);
  }

  void _drawWeeks(Canvas canvas, Offset center, double radius) {
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
      ..color = const Color(0xFF3498DB).withOpacity(0.3); // 蓝色高亮

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
        text: '${i + 1}',
        style: TextStyle(
          color: (i + 1 == currentWeek) ? Colors.blue[800] : Colors.black38,
          fontSize: 7,
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

  void _drawDaysOfYear(Canvas canvas, Offset center, double radius) {
    final int totalDays = DateTime(
      now.year + 1,
      1,
      1,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final int currentDayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    final double angleStep = 2 * pi / totalDays;
    // 将“最后一天 与 第1天”分隔线对齐到“12月末 ↔ 1月初”的月边界。
    // 月份圈当前基准下，该边界角度为 -11π/12。
    final double yearBoundaryAngle = -11 * pi / 12;
    final double startAngleOffset = yearBoundaryAngle + angleStep / 2;

    final Paint dayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.55);

    final Paint currentDayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xFF2E86C1).withValues(alpha: 0.95);

    final Paint midIntervalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF95A5A6).withValues(alpha: 0.65);

    final Paint monthBoundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = const Color(0xFF34495E).withValues(alpha: 0.7);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

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

      final double tickOuter = radius;
      final double tickInner =
          radius - (isCurrentDay ? 9.0 : (isMidIntervalDay ? 7.0 : 4.5));
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
        textPainter.text = TextSpan(
          text: '$dayInMonth',
          style: TextStyle(
            color: isCurrentDay ? Colors.blue[800] : Colors.black54,
            fontSize: isCurrentDay ? 9 : 7,
            fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.w500,
          ),
        );
        textPainter.layout();

        final labelPosition = _pointOnCircle(center, radius - 12, angle);
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
  }

  void _drawMonths(Canvas canvas, Offset center, double radius) {
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
      const Color(0xFFFFFFFF), // 1月 冬
      const Color(0xFFFFF3B0), // 2月 春（淡黄）
      const Color(0xFFFFF3B0), // 3月 春（淡黄）
      const Color(0xFFFFF3B0), // 4月 春（淡黄）
      const Color(0xFFB2DFDB), // 5月 夏
      const Color(0xFFB2DFDB), // 6月 夏
      const Color(0xFFB2DFDB), // 7月 夏
      const Color(0xFFF8C4C4), // 8月 秋（淡红）
      const Color(0xFFF8C4C4), // 9月 秋（淡红）
      const Color(0xFFF8C4C4), // 10月 秋（淡红）
      const Color(0xFFFFFFFF), // 11月 冬
      const Color(0xFFFFFFFF), // 12月 冬
    ];

    final Paint highlightMonthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFF9B59B6).withValues(alpha: 0.35); // 紫色高亮

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black12;

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
        ..color = seasonColors[i].withValues(alpha: 0.4);

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
        text: months[i],
        style: TextStyle(
          color: (month == currentMonth) ? Colors.purple[800] : Colors.black87,
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

  void _drawDial(Canvas canvas, Offset center, double radius) {
    final Paint outer = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFECF0F1);
    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black54;
    final Paint inline1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..color = Colors.black12;
    // final Paint inline2 = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 1
    //   ..color = Colors.black45;

    canvas.drawCircle(center, radius, outer);
    canvas.drawCircle(center, radius, outline);
    canvas.drawCircle(center, radius * 0.70, inline1);

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
      ..color = const Color(0xFFF1C40F).withOpacity(0.5); // 金黄色高亮

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.70),
      startAngleRad,
      sweepAngleRad,
      false,
      highlightPaint,
    );

    // 高亮当前经络 (经络圈半径0.56，宽度30)
    final Paint highlightMeridianPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFF1C40F).withOpacity(0.3); // 略淡一点

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.56),
      startAngleRad,
      sweepAngleRad,
      false,
      highlightMeridianPaint,
    );

    // 为1-24小时数字添加一个浅色背景圆环
    final Paint numberRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          28 // 加宽一点以容纳数字
      ..color = const Color.fromARGB(255, 20, 22, 23).withOpacity(0.05); // 更淡一点
    canvas.drawCircle(center, radius * 0.91, numberRingPaint);

    // canvas.drawCircle(center, radius * 0.70, inline2);

    // canvas.drawCircle(center, radius * 0.70, inline2);
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFE74C3C));
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final Paint majorPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF2C3E50);
    final Paint hourPaint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF7F8C8D);
    final Paint minutePaint = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFBDC3C7);
    final Paint branchPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black54;

    // 24小时刻度
    for (int i = 0; i < 24; i++) {
      final angle = _degToRad(i * 15 + 180);

      // 贴合外层表盘：从最外圈向内延伸
      final start = _pointOnCircle(center, radius, angle);
      final end = _pointOnCircle(center, radius - 10, angle);
      canvas.drawLine(start, end, hourPaint);
    }

    // 地支刻度
    for (int i = 0; i < 12; i += 1) {
      final angle = _degToRad(i * 30 + 180 + 15);
      final start = _pointOnCircle(center, radius * 0.70 + 18, angle);
      final end = _pointOnCircle(center, radius * 0.70 - 18, angle);
      canvas.drawLine(start, end, branchPaint);
    }
  }

  void _drawEarthBranches(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 24; i += 2) {
      final branchIndex = i ~/ 2;
      final angle = _degToRad(i * 15 + 180);
      final position = _pointOnCircle(center, radius, angle);

      textPainter.text = TextSpan(
        text: earthBranches[branchIndex],
        style: const TextStyle(
          color: Color(0xFF8E44AD),
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Microsoft YaHei',
        ),
      );

      textPainter.layout();
      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  void _drawMeridians(Canvas canvas, Offset center, double radius) {
    // 绘制经络圈背景
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..color = const Color(0xFFD5DBDB).withOpacity(0.4);
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
        text: meridians[index],
        style: const TextStyle(
          color: Color(0xFF16A085), // 蓝绿色
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

  void _drawNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final selectedHourBgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF85C1E9).withValues(alpha: 0.45);

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

  void _drawMiniteNumbers(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF90A4AE);
    canvas.drawCircle(center, radius + 12, ringPaint);

    final majorTickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF546E7A);
    final minorTickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFB0BEC5);

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
        style: const TextStyle(
          color: Color(0xFF455A64),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      );

      textPainter.layout();
      final offset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  void _drawSecondsDial(Canvas canvas, Offset center, double radius) {
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

  void _drawHands(
    Canvas canvas,
    Offset center,
    double radius,
    Offset secondsCenter,
    double secondsRadius,
  ) {
    final hourAngle = _degToRad((now.hour + now.minute / 60) * 15) + pi;
    final minuteAngle = _degToRad(now.minute * 6);
    final secondAngle = _degToRad(now.second * 6);

    final hourPaint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Colors.black45;
    final minutePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.black38;
    final secondPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.red;

    // 时分针 基于大表盘圆心 center
    canvas.drawLine(
      center,
      _pointOnCircle(center, radius * 0.84, hourAngle),
      hourPaint,
    );
    canvas.drawLine(
      center,
      _pointOnCircle(center, radius * 0.39, minuteAngle),
      minutePaint,
    );

    // 秒针 基于小表盘圆心 secondsCenter
    canvas.drawLine(
      secondsCenter,
      _pointOnCircle(secondsCenter, secondsRadius * 0.9, secondAngle),
      secondPaint,
    );
    // 绘制小秒盘中心红点
    canvas.drawCircle(secondsCenter, 3, secondPaint);
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
      oldDelegate.now.second != now.second;
}
