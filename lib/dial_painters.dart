import 'dart:math';

import 'package:flutter/material.dart';

import 'clock_painter.dart';

class BranchPlaceholderPainter extends CustomPainter {
  BranchPlaceholderPainter(
    this.title,
    this.currentIndex, {
    this.subtitle,
    this.language = DisplayLanguage.chinese,
  });

  final String title;
  final int currentIndex;
  final String? subtitle;
  final DisplayLanguage language;
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
          backgroundColor: Color(0xFFF5F7FA),
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
          text: subtitle,
          style: const TextStyle(
            color: Color(0xFF37474F),
            fontSize: 13,
            fontWeight: FontWeight.normal,
            fontFamily: 'Microsoft YaHei',
            backgroundColor: Color(0xFFF5F7FA),
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
        oldDelegate.language != language;
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
          ..color = const Color(0xFFFFD166).withValues(alpha: 0.72),
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
          backgroundColor: Color(0xFFF5F7FA),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final valuePainter = TextPainter(
      text: TextSpan(
        text: hoverLabel ?? currentLabel ?? '第${currentIndex + 1}格',
        style: const TextStyle(
          color: Color(0xFF37474F),
          fontSize: 12,
          backgroundColor: Color(0xFFF5F7FA),
        ),
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
  });

  final int currentIndex;
  final int startYear;
  final DisplayLanguage language;
  final String title;
  final String subtitle;
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
          backgroundColor: Color(0xFFF5F7FA),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(
          color: Color(0xFF37474F),
          fontSize: 13,
          fontWeight: FontWeight.normal,
          backgroundColor: Color(0xFFF5F7FA),
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
        oldDelegate.subtitle != subtitle;
  }
}
