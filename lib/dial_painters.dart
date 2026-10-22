import 'dart:math';

import 'package:flutter/material.dart';

import 'models/clock_models.dart';

class HexagramDialPlaceholderPainter extends CustomPainter {
  HexagramDialPlaceholderPainter({
    required this.colorScheme,
    this.rotation = 0,
    this.selectedName,
    this.hoveredIndex,
    this.fontScale = 1,
    required this.currentYear,
    required this.currentHuiIndex,
    required this.currentYunNumber,
    required this.currentYunIndex,
    this.showSovereignHuiLabels = false,
    this.showCurrentHuiYunNumbers = false,
  });

  final ColorScheme colorScheme;
  final double rotation;
  final String? selectedName;
  final int? hoveredIndex;
  final double fontScale;
  final int currentYear;
  final int currentHuiIndex;
  final int currentYunNumber;
  final int currentYunIndex;
  final bool showSovereignHuiLabels;
  final bool showCurrentHuiYunNumbers;

  static const sovereignHuiByHexagram = <String, String>{
    '复': '子会',
    '临': '丑会',
    '泰': '寅会',
    '大壮': '卯会',
    '夬': '辰会',
    '乾': '巳会',
    '姤': '午会',
    '遁': '未会',
    '否': '申会',
    '观': '酉会',
    '剥': '戌会',
    '坤': '亥会',
  };

  static const _sovereignHuiLabels = <String>[
    '子会',
    '丑会',
    '寅会',
    '卯会',
    '辰会',
    '巳会',
    '午会',
    '未会',
    '申会',
    '酉会',
    '戌会',
    '亥会',
  ];

  static const mainHexagramsByHuiIndex = <int, List<String>>{
    0: ['复', '颐', '屯', '益', '震'],
    1: ['噬嗑', '随', '无妄', '明夷', '贲'],
    2: ['既济', '家人', '丰', '革', '同人'],
    3: ['临', '损', '节', '中孚', '归妹'],
    4: ['睽', '兑', '履', '泰', '大畜'],
    5: ['需', '小畜', '大壮', '大有', '夬'],
    6: ['姤', '大过', '鼎', '恒', '巽'],
    7: ['井', '蛊', '升', '讼', '困'],
    8: ['未济', '解', '涣', '蒙', '师'],
    9: ['遁', '咸', '旅', '小过', '渐'],
    10: ['蹇', '艮', '谦', '否', '萃'],
    11: ['晋', '豫', '观', '比', '剥'],
  };

  static List<int> currentHuiYunNumbers(
    int currentYunNumber,
    int currentYunIndex,
  ) {
    final firstYunNumber = currentYunNumber - currentYunIndex;
    return List<int>.generate(
      30,
      (index) => firstYunNumber + index,
      growable: false,
    );
  }

  static Map<String, List<int>> currentHuiYunNumbersByHexagram({
    required int currentHuiIndex,
    required int currentYunNumber,
    required int currentYunIndex,
  }) {
    final hexagrams = mainHexagramsByHuiIndex[currentHuiIndex]!;
    final yunNumbers = currentHuiYunNumbers(currentYunNumber, currentYunIndex);
    return {
      for (var index = 0; index < hexagrams.length; index++)
        hexagrams[index]: yunNumbers.sublist(index * 6, index * 6 + 6),
    };
  }

  static const _yearsByHexagram = <String, String>{
    '恒': '2014\n2029\n2054',
    '革': '2015\n2062',
    '丰': '2016\n2057',
    '明夷': '2017\n2020\n2052',
    '贲': '2018\n2021\n2072',
    '既济': '2019\n2022\n2047',
    '家人': '2023',
    '小过': '2024',
    '随': '2025\n2063',
    '姤': '2026\n2064',
    '大过': '2027\n2059',
    '鼎': '2028',
    '巽': '2030',
    '井': '2031\n2044',
    '蛊': '2032\n2069',
    '升': '2033\n2049',
    '讼': '2034',
    '困': '2035',
    '未济': '2036',
    '解': '2037',
    '涣': '2038',
    '蒙': '2039',
    '师': '2040',
    '遁': '2041',
    '咸': '2042',
    '旅': '2043',
    '需': '2045',
    '节': '2046',
    '屯': '2048',
    '泰': '2050',
    '临': '2051',
    '复': '2053',
    '大壮': '2055',
    '归妹': '2056',
    '震': '2058',
    '夬': '2060',
    '兑': '2061',
    '乾': '2065',
    '履': '2066',
    '同人': '2067',
    '无妄': '2068',
    '大畜': '2070',
    '损': '2071',
    '颐': '2073',
  };

  static String? hexagramForYear(int year) {
    final targetYear = year.toString();
    for (final entry in _yearsByHexagram.entries) {
      if (entry.value.split('\n').contains(targetYear)) {
        return entry.key;
      }
    }
    return null;
  }

  static bool hasYearLabelsForYear(int year) => hexagramForYear(year) != null;

  static int? hexagramIndexAt(
    Offset position,
    Size size, {
    double rotation = 0,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final offset = position - center;
    final radius = size.shortestSide / 2 - 6;
    if (offset.distance < radius * 0.68 || offset.distance > radius * 0.96) {
      return null;
    }

    const segmentAngle = 2 * pi / 64;
    const startAngle = -pi / 2 - segmentAngle;
    final relativeAngle =
        (atan2(offset.dy, offset.dx) - rotation - startAngle) % (2 * pi);
    return (relativeAngle / segmentAngle).floor();
  }

  static const _names = <String>[
    '乾',
    '坤',
    '屯',
    '蒙',
    '需',
    '讼',
    '师',
    '比',
    '小畜',
    '履',
    '泰',
    '否',
    '同人',
    '大有',
    '谦',
    '豫',
    '随',
    '蛊',
    '临',
    '观',
    '噬嗑',
    '贲',
    '剥',
    '复',
    '无妄',
    '大畜',
    '颐',
    '大过',
    '坎',
    '离',
    '咸',
    '恒',
    '遁',
    '大壮',
    '晋',
    '明夷',
    '家人',
    '睽',
    '蹇',
    '解',
    '损',
    '益',
    '夬',
    '姤',
    '萃',
    '升',
    '困',
    '井',
    '革',
    '鼎',
    '震',
    '艮',
    '渐',
    '归妹',
    '丰',
    '旅',
    '巽',
    '兑',
    '涣',
    '节',
    '中孚',
    '小过',
    '既济',
    '未济',
  ];

  static const _symbols = <String>[
    '䷀',
    '䷁',
    '䷂',
    '䷃',
    '䷄',
    '䷅',
    '䷆',
    '䷇',
    '䷈',
    '䷉',
    '䷊',
    '䷋',
    '䷌',
    '䷍',
    '䷎',
    '䷏',
    '䷐',
    '䷑',
    '䷒',
    '䷓',
    '䷔',
    '䷕',
    '䷖',
    '䷗',
    '䷘',
    '䷙',
    '䷚',
    '䷛',
    '䷜',
    '䷝',
    '䷞',
    '䷟',
    '䷠',
    '䷡',
    '䷢',
    '䷣',
    '䷤',
    '䷥',
    '䷦',
    '䷧',
    '䷨',
    '䷩',
    '䷪',
    '䷫',
    '䷬',
    '䷭',
    '䷮',
    '䷯',
    '䷰',
    '䷱',
    '䷲',
    '䷳',
    '䷴',
    '䷵',
    '䷶',
    '䷷',
    '䷸',
    '䷹',
    '䷺',
    '䷻',
    '䷼',
    '䷽',
    '䷾',
    '䷿',
  ];

  // Clockwise outer-ring order from the reference circular arrangement.
  static const _circleNames = <String>[
    '乾',
    '姤',
    '大过',
    '鼎',
    '恒',
    '巽',
    '井',
    '蛊',
    '升',
    '讼',
    '困',
    '未济',
    '解',
    '涣',
    '坎',
    '蒙',
    '师',
    '遁',
    '咸',
    '旅',
    '小过',
    '渐',
    '蹇',
    '艮',
    '谦',
    '否',
    '萃',
    '晋',
    '豫',
    '观',
    '比',
    '剥',
    '坤',
    '复',
    '颐',
    '屯',
    '益',
    '震',
    '噬嗑',
    '随',
    '无妄',
    '明夷',
    '贲',
    '既济',
    '家人',
    '丰',
    '离',
    '革',
    '同人',
    '临',
    '损',
    '节',
    '中孚',
    '归妹',
    '睽',
    '兑',
    '履',
    '泰',
    '大畜',
    '需',
    '小畜',
    '大壮',
    '大有',
    '夬',
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    final radius = size.shortestSide / 2 - 6;
    final outerRingRadius = radius * 0.96;
    final nameRadius = radius * 0.87;
    final symbolRadius = radius * 0.76;
    final segmentAngle = 2 * pi / 64;
    final startAngle = -pi / 2 - segmentAngle;
    final hasCurrentYearLabels = hasYearLabelsForYear(currentYear);

    canvas.drawCircle(
      center,
      outerRingRadius,
      Paint()..color = colorScheme.surfaceContainerLowest,
    );
    final alternatingBandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.28
      ..strokeCap = StrokeCap.butt
      ..color = colorScheme.primary.withValues(alpha: 0.08);
    for (var index = 0; index < 64; index += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        startAngle + index * segmentAngle,
        segmentAngle,
        false,
        alternatingBandPaint,
      );
    }
    if (selectedName != null) {
      final selectedIndex = _circleNames.indexOf(selectedName!);
      if (selectedIndex >= 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.82),
          startAngle + selectedIndex * segmentAngle,
          segmentAngle,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.28
            ..strokeCap = StrokeCap.butt
            ..color = const Color(0xFFBDE3F8),
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRingRadius - 1.5),
          startAngle + selectedIndex * segmentAngle,
          segmentAngle,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.butt
            ..color = const Color(0xFFBDE3F8),
        );
      }
    }
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 64) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        startAngle + hoveredIndex! * segmentAngle,
        segmentAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.28
          ..strokeCap = StrokeCap.butt
          ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.68),
      );
    }
    canvas.drawCircle(
      center,
      radius * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = colorScheme.outline.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      center,
      outerRingRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = colorScheme.outline.withValues(alpha: 0.6),
    );
    for (var index = 0; index < 64; index++) {
      final boundaryAngle = startAngle + index * segmentAngle;
      final angle = boundaryAngle + segmentAngle / 2;
      final name = _circleNames[index];
      final symbol = _symbols[_names.indexOf(name)];
      canvas.drawLine(
        Offset(
          center.dx + cos(boundaryAngle) * (outerRingRadius - 6),
          center.dy + sin(boundaryAngle) * (outerRingRadius - 6),
        ),
        Offset(
          center.dx + cos(boundaryAngle) * outerRingRadius,
          center.dy + sin(boundaryAngle) * outerRingRadius,
        ),
        Paint()
          ..strokeWidth = 0.7
          ..color = colorScheme.outline.withValues(alpha: 0.35),
      );

      final namePainter =
          TextPainter(
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            )
            ..text = TextSpan(
              text: name.split('').join('\n'),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.normal,
              ),
            )
            ..layout(maxWidth: 30);
      final symbolPainter =
          TextPainter(
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            )
            ..text = TextSpan(
              text: symbol,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 26 * fontScale,
                fontFamily: 'Noto Sans Symbols 2',
              ),
            )
            ..layout(maxWidth: 24);
      final namePosition = Offset(
        center.dx + cos(angle) * nameRadius,
        center.dy + sin(angle) * nameRadius,
      );
      final symbolPosition = Offset(
        center.dx + cos(angle) * symbolRadius,
        center.dy + sin(angle) * symbolRadius,
      );
      canvas.save();
      canvas.translate(namePosition.dx, namePosition.dy);
      canvas.rotate(angle + pi / 2);
      namePainter.paint(
        canvas,
        Offset(-namePainter.width / 2, -namePainter.height / 2),
      );
      canvas.restore();
      canvas.save();
      canvas.translate(symbolPosition.dx, symbolPosition.dy);
      canvas.rotate(angle + pi / 2);
      symbolPainter.paint(
        canvas,
        Offset(-symbolPainter.width / 2, -symbolPainter.height / 2),
      );
      canvas.restore();

      final showSovereignHuiLabels = this.showSovereignHuiLabels;
      final years = _yearsByHexagram[name];
      if (years != null &&
          hasCurrentYearLabels &&
          !showSovereignHuiLabels &&
          !showCurrentHuiYunNumbers) {
        final isYearHighlighted = name == selectedName || index == hoveredIndex;
        final yearLabels = years.split('\n');
        final yearsPainter = TextPainter(
          text: TextSpan(
            style: TextStyle(
              color: isYearHighlighted
                  ? const Color(0xFF2878A8)
                  : colorScheme.onSurface.withValues(alpha: 0.78),
              fontSize: (isYearHighlighted ? 11 : 9) * fontScale,
            ),
            children: yearLabels
                .asMap()
                .entries
                .map((yearEntry) {
                  final isCurrentYear =
                      yearEntry.value == currentYear.toString();
                  return TextSpan(
                    text: yearEntry.key == yearLabels.length - 1
                        ? yearEntry.value
                        : '${yearEntry.value}\n',
                    style: TextStyle(
                      color: isYearHighlighted
                          ? const Color(0xFF2878A8)
                          : isCurrentYear
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.78),
                      fontSize:
                          (isYearHighlighted || isCurrentYear ? 11 : 9) *
                          fontScale,
                      fontWeight: isYearHighlighted || isCurrentYear
                          ? FontWeight.w900
                          : FontWeight.normal,
                    ),
                  );
                })
                .toList(growable: false),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 42);
        final yearsPosition = Offset(
          center.dx + cos(angle) * (outerRingRadius + 18),
          center.dy + sin(angle) * (outerRingRadius + 18),
        );
        canvas.save();
        canvas.translate(yearsPosition.dx, yearsPosition.dy);
        canvas.rotate(-rotation);
        yearsPainter.paint(
          canvas,
          Offset(-yearsPainter.width / 2, -yearsPainter.height / 2),
        );
        canvas.restore();
      }

      if (showSovereignHuiLabels) {
        final hui = sovereignHuiByHexagram[name];
        if (hui != null) {
          final isCurrentHui = hui == _sovereignHuiLabels[currentHuiIndex];
          final huiPainter = TextPainter(
            text: TextSpan(
              text: hui,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12 * fontScale,
                fontWeight: isCurrentHui ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(maxWidth: 52);
          final huiPosition = Offset(
            center.dx + cos(angle) * (outerRingRadius + 18),
            center.dy + sin(angle) * (outerRingRadius + 18),
          );
          canvas.save();
          canvas.translate(huiPosition.dx, huiPosition.dy);
          canvas.rotate(-rotation);
          huiPainter.paint(
            canvas,
            Offset(-huiPainter.width / 2, -huiPainter.height / 2),
          );
          canvas.restore();
        }
      }
    }

    if (showCurrentHuiYunNumbers) {
      final huiHexagrams = mainHexagramsByHuiIndex[currentHuiIndex]!;
      final yunNumbersByHexagram = currentHuiYunNumbersByHexagram(
        currentHuiIndex: currentHuiIndex,
        currentYunNumber: currentYunNumber,
        currentYunIndex: currentYunIndex,
      );
      for (var groupIndex = 0; groupIndex < huiHexagrams.length; groupIndex++) {
        final hexagram = huiHexagrams[groupIndex];
        final hexagramIndex = _circleNames.indexOf(hexagram);
        if (hexagramIndex < 0) {
          continue;
        }
        final angle = startAngle + (hexagramIndex + 0.5) * segmentAngle;
        final yunNumbers = yunNumbersByHexagram[hexagram]!;
        for (var yunIndex = 0; yunIndex < yunNumbers.length; yunIndex++) {
          final isCurrentYun = groupIndex * 6 + yunIndex == currentYunIndex;
          final labelPainter = TextPainter(
            text: TextSpan(
              text: '${yunNumbers[yunIndex]}',
              style: TextStyle(
                color: isCurrentYun
                    ? colorScheme.primary
                    : groupIndex == currentYunIndex ~/ 6
                    ? colorScheme.primary.withValues(alpha: 0.72)
                    : colorScheme.onSurface,
                fontSize: 8 * fontScale,
                fontWeight: isCurrentYun ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(maxWidth: 28);
          final labelRadius = outerRingRadius + 12 + yunIndex * 7;
          final labelPosition = Offset(
            center.dx + cos(angle) * labelRadius,
            center.dy + sin(angle) * labelRadius,
          );
          canvas.save();
          canvas.translate(labelPosition.dx, labelPosition.dy);
          canvas.rotate(-rotation);
          labelPainter.paint(
            canvas,
            Offset(-labelPainter.width / 2, -labelPainter.height / 2),
          );
          canvas.restore();
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HexagramDialPlaceholderPainter oldDelegate) =>
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.rotation != rotation ||
      oldDelegate.selectedName != selectedName ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.fontScale != fontScale ||
      oldDelegate.currentYear != currentYear ||
      oldDelegate.currentHuiIndex != currentHuiIndex ||
      oldDelegate.currentYunNumber != currentYunNumber ||
      oldDelegate.currentYunIndex != currentYunIndex ||
      oldDelegate.showSovereignHuiLabels != showSovereignHuiLabels ||
      oldDelegate.showCurrentHuiYunNumbers != showCurrentHuiYunNumbers;
}

void _drawSmallDialHoverCenter(
  Canvas canvas,
  Offset center,
  Rect ringRect,
  double ringWidth,
  bool isHovered,
) {
  if (!isHovered) {
    return;
  }
  canvas.drawCircle(
    center,
    ringRect.shortestSide / 2 - ringWidth / 2,
    Paint()..color = const Color(0xFFFFF2CC),
  );
}

class BranchPlaceholderPainter extends CustomPainter {
  BranchPlaceholderPainter(
    this.title,
    this.currentIndex, {
    this.subtitle,
    this.language = DisplayLanguage.chinese,
    this.hoveredIndex,
    this.hoverLabel,
  });

  final String title;
  final int currentIndex;
  final String? subtitle;
  final DisplayLanguage language;
  final int? hoveredIndex;
  final String? hoverLabel;
  static const List<String> branches = <String>[
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

  String _branchLabel(int index) => language == DisplayLanguage.english
      ? const [
          'Zi',
          'Chou',
          'Yin',
          'Mao',
          'Chen',
          'Si',
          'Wu',
          'Wei',
          'Shen',
          'You',
          'Xu',
          'Hai',
        ][index]
      : branches[index];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    final scale = size.shortestSide / 44;
    final step = 2 * pi / branches.length;
    final startAngle = pi / 2 - step / 2;

    final ringWidth = radius * 0.34;
    final ringRadius = radius - ringWidth / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF5F7FA));
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = const Color(0xFFE4E9ED),
    );
    _drawSmallDialHoverCenter(
      canvas,
      center,
      ringRect,
      ringWidth,
      hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 12,
    );
    canvas.drawArc(
      ringRect,
      startAngle + currentIndex * step,
      step,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0xFFBDE3F8),
    );
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 12) {
      canvas.drawArc(
        ringRect,
        startAngle + hoveredIndex! * step,
        step,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..strokeCap = StrokeCap.butt
          ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.68),
      );
    }
    canvas.drawCircle(
      center,
      ringRadius - ringWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final separatorPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 0.35 * scale;
    for (int i = 0; i < branches.length; i += 1) {
      final angle = startAngle + i * step;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * (ringRadius - ringWidth / 2),
          center.dy + sin(angle) * (ringRadius - ringWidth / 2),
        ),
        Offset(
          center.dx + cos(angle) * (ringRadius + ringWidth / 2),
          center.dy + sin(angle) * (ringRadius + ringWidth / 2),
        ),
        separatorPaint,
      );
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < branches.length; i += 1) {
      final angle = startAngle + (i + 0.5) * step;
      final position = Offset(
        center.dx + cos(angle) * ringRadius,
        center.dy + sin(angle) * ringRadius,
      );
      textPainter.text = TextSpan(
        text: _branchLabel(i),
        style: const TextStyle(
          color: Color(0xFF8E44AD),
          fontSize: 13,
          fontWeight: FontWeight.normal,
          fontFamily: 'Microsoft YaHei',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF37474F),
          fontSize: 19,
          fontWeight: FontWeight.normal,
          fontFamily: 'Microsoft YaHei',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final firstLineTop = center.dy - 22;
    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2, firstLineTop),
    );
    if (subtitle != null) {
      final subtitlePainter = TextPainter(
        text: TextSpan(
          text: hoverLabel ?? subtitle,
          style: const TextStyle(
            color: Color(0xFF37474F),
            fontSize: 13,
            fontWeight: FontWeight.normal,
            fontFamily: 'Microsoft YaHei',
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final secondLineTop = center.dy + 12;
      subtitlePainter.paint(
        canvas,
        Offset(center.dx - subtitlePainter.width / 2, secondLineTop),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BranchPlaceholderPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.language != language ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoverLabel != hoverLabel;
  }
}

class ThirtySegmentDialPainter extends CustomPainter {
  ThirtySegmentDialPainter(
    this.currentIndex, {
    this.title = '运',
    this.labels = const <String>[],
    this.labelIndices = const <int>[0, 4, 9, 14, 19, 24, 29],
    this.startAtBottom = false,
    this.rotateLabels = false,
    this.hideCurrentLabel = false,
    this.titleFontSize = 19,
    this.currentLabelOffsetY = 12,
    this.hoveredIndex,
    this.hoverLabel,
    this.currentLabel,
  });

  final int currentIndex;
  final String title;
  final List<String> labels;
  final List<int> labelIndices;
  final bool startAtBottom;
  final bool rotateLabels;
  final bool hideCurrentLabel;
  final double titleFontSize;
  final double currentLabelOffsetY;
  final int? hoveredIndex;
  final String? hoverLabel;
  final String? currentLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    final scale = size.shortestSide / 44;
    final step = 2 * pi / 30;
    final startAngle = (startAtBottom ? pi / 2 : -pi / 2) - step / 2;
    final ringWidth = radius * 0.34;
    final ringRadius = radius - ringWidth / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF5F7FA));
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = const Color(0xFFE4E9ED),
    );
    _drawSmallDialHoverCenter(
      canvas,
      center,
      ringRect,
      ringWidth,
      hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 30,
    );
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 30) {
      canvas.drawArc(
        ringRect,
        startAngle + hoveredIndex! * step,
        step,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..strokeCap = StrokeCap.butt
          ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.68),
      );
    }
    canvas.drawArc(
      ringRect,
      startAngle + currentIndex * step,
      step,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0xFFBDE3F8),
    );

    canvas.drawCircle(
      center,
      ringRadius - ringWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final separatorPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 0.35 * scale;
    for (int i = 0; i < 30; i += 1) {
      final angle = startAngle + i * step;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * (ringRadius - ringWidth / 2),
          center.dy + sin(angle) * (ringRadius - ringWidth / 2),
        ),
        Offset(
          center.dx + cos(angle) * (ringRadius + ringWidth / 2),
          center.dy + sin(angle) * (ringRadius + ringWidth / 2),
        ),
        separatorPaint,
      );
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (final int index in labelIndices) {
      if (hideCurrentLabel && index == currentIndex) {
        continue;
      }
      final angle = startAngle + (index + 0.5) * step;
      final position = Offset(
        center.dx + cos(angle) * ringRadius,
        center.dy + sin(angle) * ringRadius,
      );
      textPainter.text = TextSpan(
        text: labels.isEmpty ? '${index + 1}' : labels[index],
        style: TextStyle(
          color: const Color(0xFF5D6D7E),
          fontSize: labels.isEmpty ? 11 : 8,
          fontWeight:
              labels.isNotEmpty &&
                  (labels[index] == '2014' ||
                      (rotateLabels && index == currentIndex))
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
      textPainter.layout();
      if (rotateLabels) {
        canvas.save();
        canvas.translate(position.dx, position.dy);
        final labelAngle = index < 15 ? angle + pi : angle;
        canvas.rotate(labelAngle);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      } else {
        textPainter.paint(
          canvas,
          position - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Color(0xFF37474F),
          fontSize: titleFontSize,
          fontWeight: FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final valuePainter = TextPainter(
      text: TextSpan(
        text: hoverLabel ?? currentLabel ?? '第${currentIndex + 1}格',
        style: const TextStyle(color: Color(0xFF37474F), fontSize: 12),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final firstLineTop = center.dy - 22;
    final secondLineTop = center.dy + 12;
    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2, firstLineTop),
    );
    valuePainter.paint(
      canvas,
      Offset(center.dx - valuePainter.width / 2, secondLineTop),
    );
  }

  @override
  bool shouldRepaint(covariant ThirtySegmentDialPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.title != title ||
        oldDelegate.labels != labels ||
        oldDelegate.labelIndices != labelIndices ||
        oldDelegate.startAtBottom != startAtBottom ||
        oldDelegate.rotateLabels != rotateLabels ||
        oldDelegate.hideCurrentLabel != hideCurrentLabel ||
        oldDelegate.titleFontSize != titleFontSize ||
        oldDelegate.currentLabelOffsetY != currentLabelOffsetY ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoverLabel != hoverLabel ||
        oldDelegate.currentLabel != currentLabel;
  }
}

class TwelveSegmentDialPainter extends CustomPainter {
  TwelveSegmentDialPainter(
    this.currentIndex,
    this.startYear, {
    this.language = DisplayLanguage.chinese,
    this.title = '星乙192运',
    this.subtitle = '辰戌2303世',
    this.hoveredIndex,
    this.hoverLabel,
  });

  final int currentIndex;
  final int startYear;
  final DisplayLanguage language;
  final String title;
  final String subtitle;
  final int? hoveredIndex;
  final String? hoverLabel;
  static const branches = <String>[
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    final step = 2 * pi / 12;
    final startAngle = pi / 2 - step / 2;
    const branches = <String>[
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
    final ringWidth = radius * 0.34;
    final ringRadius = radius - ringWidth / 2;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF5F7FA));
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..color = const Color(0xFFE4E9ED),
    );
    _drawSmallDialHoverCenter(
      canvas,
      center,
      ringRect,
      ringWidth,
      hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 12,
    );
    canvas.drawArc(
      ringRect,
      startAngle + currentIndex * step,
      step,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0xFFBDE3F8),
    );
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < 12) {
      canvas.drawArc(
        ringRect,
        startAngle + hoveredIndex! * step,
        step,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..strokeCap = StrokeCap.butt
          ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.68),
      );
    }

    canvas.drawCircle(
      center,
      ringRadius - ringWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final separatorPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 0.35 * size.shortestSide / 44;
    for (int i = 0; i < 12; i += 1) {
      final angle = startAngle + i * step;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * (ringRadius - ringWidth / 2),
          center.dy + sin(angle) * (ringRadius - ringWidth / 2),
        ),
        Offset(
          center.dx + cos(angle) * (ringRadius + ringWidth / 2),
          center.dy + sin(angle) * (ringRadius + ringWidth / 2),
        ),
        separatorPaint,
      );
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int index = 0; index < 12; index += 1) {
      final angle = startAngle + (index + 0.5) * step;
      final position = Offset(
        center.dx + cos(angle) * ringRadius,
        center.dy + sin(angle) * ringRadius,
      );
      textPainter.text = TextSpan(
        text: language == DisplayLanguage.english
            ? const [
                'Zi',
                'Chou',
                'Yin',
                'Mao',
                'Chen',
                'Si',
                'Wu',
                'Wei',
                'Shen',
                'You',
                'Xu',
                'Hai',
              ][index]
            : branches[index],
        style: const TextStyle(
          color: Color(0xFF8E44AD),
          fontSize: 13,
          fontWeight: FontWeight.normal,
          fontFamily: 'Microsoft YaHei',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF37474F),
          fontSize: 19,
          fontWeight: FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: hoverLabel ?? subtitle,
        style: const TextStyle(
          color: Color(0xFF37474F),
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final titleTop = center.dy - 22;
    final subtitleTop = center.dy + 12;

    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2, titleTop),
    );
    subtitlePainter.paint(
      canvas,
      Offset(center.dx - subtitlePainter.width / 2, subtitleTop),
    );
  }

  @override
  bool shouldRepaint(covariant TwelveSegmentDialPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.startYear != startYear ||
        oldDelegate.language != language ||
        oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoverLabel != hoverLabel;
  }
}
