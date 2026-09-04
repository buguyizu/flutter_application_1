import 'dart:math';

import 'package:flutter/material.dart';

int? dialIndexAt(Offset position, int segmentCount) {
  const center = Offset(88, 122);
  final delta = position - center;
  if (delta.distance > 88) {
    return null;
  }
  final step = 2 * pi / segmentCount;
  final startAngle = pi / 2 - step / 2;
  final angle = atan2(delta.dy, delta.dx);
  var relativeAngle = (angle - startAngle) % (2 * pi);
  if (relativeAngle < 0) relativeAngle += 2 * pi;
  return (relativeAngle / step).floor().clamp(0, segmentCount - 1);
}
