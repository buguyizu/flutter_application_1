import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' show cos, pi, sin;

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/clock_painter.dart';
import 'package:flutter_application_1/dial_painters.dart';
import 'package:flutter_application_1/models/clock_calculations.dart';
import 'package:flutter_application_1/models/clock_models.dart';
import 'package:flutter_application_1/widgets/dial_geometry.dart';

Future<void> pumpClockApp(
  WidgetTester tester, {
  Size viewportSize = const Size(1000, 900),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ClockApp());
  final page = find.byKey(const ValueKey('left_panel_container'));
  for (var frame = 0; frame < 20 && page.evaluate().isEmpty; frame += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(page, findsOneWidget);
}

void main() {
  test('maps all twelve sovereign hexagrams to their hui', () {
    expect(
      HexagramDialPlaceholderPainter.sovereignHuiByHexagram,
      hasLength(12),
    );
    expect(HexagramDialPlaceholderPainter.sovereignHuiByHexagram['乾'], '巳会');
    expect(HexagramDialPlaceholderPainter.sovereignHuiByHexagram['复'], '子会');
    expect(HexagramDialPlaceholderPainter.sovereignHuiByHexagram['遁'], '未会');
  });

  test('maps each hui to five main hexagrams', () {
    final mainHexagrams =
        HexagramDialPlaceholderPainter.mainHexagramsByHuiIndex;
    expect(mainHexagrams, hasLength(12));
    expect(mainHexagrams.values, everyElement(hasLength(5)));
    expect(mainHexagrams[6], ['姤', '大过', '鼎', '恒', '巽']);
    expect(mainHexagrams[9]!.first, '遁');

    final currentTime = DateTime(2026);
    final huiIndex = ClockCalculations.huiIndex(currentTime);
    final mainHexagramIndex = ClockCalculations.yunIndex(currentTime) ~/ 6;
    expect(mainHexagrams[huiIndex]![mainHexagramIndex], '大过');

    final currentYunNumber = ClockCalculations.yunNumber(currentTime);
    final currentYunIndex = ClockCalculations.yunIndex(currentTime);
    expect(currentYunNumber, 192);
    expect(currentYunIndex, 11);
    expect(
      HexagramDialPlaceholderPainter.currentHuiYunNumbers(
        currentYunNumber,
        currentYunIndex,
      ),
      List<int>.generate(30, (index) => 181 + index),
    );
    expect(
      HexagramDialPlaceholderPainter.currentHuiYunNumbersByHexagram(
        currentHuiIndex: huiIndex,
        currentYunNumber: currentYunNumber,
        currentYunIndex: currentYunIndex,
      ),
      {
        '姤': [181, 182, 183, 184, 185, 186],
        '大过': [187, 188, 189, 190, 191, 192],
        '鼎': [193, 194, 195, 196, 197, 198],
        '恒': [199, 200, 201, 202, 203, 204],
        '巽': [205, 206, 207, 208, 209, 210],
      },
    );
  });

  test('finds the known hexagram for a year', () {
    expect(HexagramDialPlaceholderPainter.hexagramForYear(2026), '姤');
    expect(HexagramDialPlaceholderPainter.hexagramForYear(2027), '大过');
    expect(HexagramDialPlaceholderPainter.hasYearLabelsForYear(2026), isTrue);
    expect(HexagramDialPlaceholderPainter.hasYearLabelsForYear(2074), isFalse);
  });

  testWidgets('shows the app title without a version number', (tester) async {
    await pumpClockApp(tester);

    expect(find.text('Time Flow'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1.0.1'), findsNothing);
  });

  testWidgets('can collapse the left dial column', (tester) async {
    await pumpClockApp(tester);

    final leftPanel = find.byKey(const ValueKey('left_panel_container'));
    expect(leftPanel, findsOneWidget);

    final initialWidth = tester.getSize(leftPanel).width;
    expect(initialWidth, greaterThan(100));

    await tester.ensureVisible(
      find.byKey(const ValueKey('toggle_left_panel_button')),
    );
    await tester.tap(find.byKey(const ValueKey('toggle_left_panel_button')));
    await tester.pumpAndSettle();

    final collapsedWidth = tester.getSize(leftPanel).width;
    expect(collapsedWidth, equals(initialWidth));
  });

  testWidgets('shows the dial controls and four small dials', (tester) async {
    await pumpClockApp(tester);

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeast(4));
  });

  testWidgets('supports zoom, layer menu, and protection toggle', (
    tester,
  ) async {
    await pumpClockApp(tester);

    Future<void> tapIcon(IconData icon) async {
      final finder = find.byIcon(icon);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    await tapIcon(Icons.add);
    await tapIcon(Icons.remove);

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);

    final rightPanelButton = find.byKey(
      const ValueKey('toggle_right_panel_button'),
    );
    await tester.ensureVisible(rightPanelButton);
    await tester.tap(rightPanelButton);
    await tester.pump();
    await tester.tap(rightPanelButton);
  });

  testWidgets('hides panel toggles on mobile but keeps dial mode switches', (
    tester,
  ) async {
    await pumpClockApp(tester, viewportSize: const Size(390, 844));

    expect(
      find.byKey(const ValueKey('toggle_left_panel_button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('toggle_right_panel_button')),
      findsNothing,
    );
    expect(find.text('Day dial'), findsOneWidget);
    expect(find.text('Hexagram dial'), findsOneWidget);

    final mainDialFace = find.byKey(const ValueKey('main_dial_face'));
    final initialDialSize = tester.getSize(mainDialFace).width;
    expect(initialDialSize, lessThan(358));
    final zoomInButton = find.byIcon(Icons.add);
    await tester.ensureVisible(zoomInButton);
    await tester.tap(zoomInButton);
    await tester.pumpAndSettle();
    final enlargedDialSize = tester.getSize(mainDialFace).width;
    expect(enlargedDialSize, greaterThan(initialDialSize));

    final zoomOutButton = find.byIcon(Icons.remove);
    await tester.ensureVisible(zoomOutButton);
    await tester.tap(zoomOutButton);
    await tester.pumpAndSettle();
    expect(tester.getSize(mainDialFace).width, closeTo(initialDialSize, 0.01));

    final clockPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<ClockPainter>()
        .single;
    expect(clockPainter.visibleRings, isNot(contains(ClockDialRing.months)));
    expect(clockPainter.visibleRings, isNot(contains(ClockDialRing.weeks)));
    expect(clockPainter.visibleRings, isNot(contains(ClockDialRing.days)));
    expect(clockPainter.visibleRings, isNot(contains(ClockDialRing.seconds)));
    expect(clockPainter.visibleRings, isNot(contains(ClockDialRing.meridians)));
    expect(clockPainter.hourRingFontSize, 12);
    expect(clockPainter.currentHourRingFontSize, 14);
    expect(clockPainter.hourBaseFactor, 0.96);
    expect(clockPainter.protectionRayReachFactor, 3);
    expect(clockPainter.rotatingGeneralFontSize, 12);
    expect(clockPainter.rotatingBranchFontSize, 8);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('main_dial_caption')))
          .style
          ?.fontSize,
      16,
    );

    final smallDialPaints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where(
          (customPaint) =>
              customPaint.painter is BranchPlaceholderPainter ||
              customPaint.painter is ThirtySegmentDialPainter ||
              customPaint.painter is TwelveSegmentDialPainter,
        )
        .toList();
    expect(smallDialPaints, hasLength(4));
    for (final customPaint in smallDialPaints) {
      expect(tester.getSize(find.byWidget(customPaint)), const Size(176, 176));
    }

    final mobileHexagramTab = find.text('Hexagram dial');
    await tester.ensureVisible(mobileHexagramTab);
    await tester.tap(mobileHexagramTab);
    await tester.pumpAndSettle();
    final mobileHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(mobileHexagramPainter.fontScale, 0.72);
    expect(mobileHexagramPainter.currentYear, DateTime.now().year);
    expect(mobileHexagramPainter.showSovereignHuiLabels, isFalse);
    expect(find.textContaining('Yun 192 - 大过 Hexagram'), findsOneWidget);
    expect(
      find.textContaining('2026 Bingwu Year - 姤 Hexagram'),
      findsOneWidget,
    );

    final yearDial = find.byKey(const ValueKey('fourth_small_dial'));
    await tester.ensureVisible(yearDial);
    final startYear = ClockCalculations.yearCycleStart(DateTime.now().year);
    const selectedYear = 2027;
    final yearIndex = selectedYear - startYear;
    expect(yearIndex, inInclusiveRange(0, 29));
    const segmentStep = 2 * pi / 30;
    final yearCellAngle =
        pi / 2 - segmentStep / 2 + (yearIndex + 0.5) * segmentStep;
    final yearCellPosition = Offset(
      88 + cos(yearCellAngle) * 60,
      122 + sin(yearCellAngle) * 60,
    );
    expect(dialIndexAt(yearCellPosition, 30), yearIndex);
    await tester.tapAt(tester.getTopLeft(yearDial) + yearCellPosition);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final selectedYearPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(selectedYearPainter.currentYear, selectedYear);
    expect(
      find.textContaining('2027 Dingwei Year - 大过 Hexagram'),
      findsOneWidget,
    );

    final appTitle = find.text('Time Flow').first;
    await tester.ensureVisible(appTitle);
    await tester.tapAt(
      tester.getCenter(appTitle),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    final resetYearPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(resetYearPainter.currentYear, DateTime.now().year);
    expect(
      find.textContaining('2026 Bingwu Year - 姤 Hexagram'),
      findsOneWidget,
    );

    await tester.ensureVisible(mainDialFace);
    final mainDialSize = tester.getSize(mainDialFace);
    final ringRadius = (mainDialSize.shortestSide / 2 - 6) * 0.82;
    final localHoverPosition = Offset(
      mainDialSize.width / 2 + ringRadius,
      mainDialSize.height / 2,
    );
    final expectedHoveredIndex = HexagramDialPlaceholderPainter.hexagramIndexAt(
      localHoverPosition,
      mainDialSize,
    );
    expect(expectedHoveredIndex, isNotNull);

    final hexagramHover = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hexagramHover.addPointer(
      location: tester.getTopLeft(mainDialFace) + localHoverPosition,
    );
    await hexagramHover.moveTo(
      tester.getTopLeft(mainDialFace) + localHoverPosition,
    );
    await tester.pumpAndSettle();
    final hoveredPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(hoveredPainter.hoveredIndex, expectedHoveredIndex);
    await hexagramHover.removePointer();
    await tester.pumpAndSettle();
    final unhoveredPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(unhoveredPainter.hoveredIndex, isNull);

    final mobileDayTab = find.text('Day dial');
    await tester.ensureVisible(mobileDayTab);
    await tester.tap(mobileDayTab);
    await tester.pumpAndSettle();
    expect(find.text('64 Hexagrams'), findsNothing);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .whereType<HexagramDialPlaceholderPainter>(),
      isEmpty,
    );

    final firstSmallDial = find.byKey(const ValueKey('first_small_dial'));
    await tester.ensureVisible(firstSmallDial);
    final smallDialCenter = tester.getCenter(firstSmallDial);
    final hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer(location: smallDialCenter);
    await hoverGesture.moveTo(smallDialCenter);
    await tester.pumpAndSettle();
    final hoveredHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(hoveredHexagramPainter.showSovereignHuiLabels, isTrue);
    await hoverGesture.removePointer();
    await tester.pumpAndSettle();
    expect(find.text('64 Hexagrams'), findsNothing);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .whereType<HexagramDialPlaceholderPainter>(),
      isEmpty,
    );

    final secondSmallDial = find.byKey(const ValueKey('second_small_dial'));
    await tester.ensureVisible(secondSmallDial);
    final secondDialCenter = tester.getCenter(secondSmallDial);
    final secondDialHover = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await secondDialHover.addPointer(location: secondDialCenter);
    await secondDialHover.moveTo(secondDialCenter);
    await tester.pumpAndSettle();
    final secondDialHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(secondDialHexagramPainter.showCurrentHuiYunNumbers, isTrue);
    expect(secondDialHexagramPainter.currentYunNumber, 192);
    expect(secondDialHexagramPainter.currentYunIndex, 11);
    await secondDialHover.removePointer();
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .whereType<HexagramDialPlaceholderPainter>(),
      isEmpty,
    );

    final thirdSmallDial = find.byKey(const ValueKey('third_small_dial'));
    await tester.ensureVisible(thirdSmallDial);
    final currentYear = DateTime.now().year;
    final currentShiIndex = ClockCalculations.shiIndex(DateTime(currentYear));
    final selectedShiIndex = (currentShiIndex + 1) % 12;
    final selectedShiYear = ClockCalculations.yearCycleStart(
      currentYear +
          (selectedShiIndex - currentShiIndex) * ClockCalculations.yearsPerShi,
    );
    const shiStep = 2 * pi / 12;
    final shiCellAngle =
        pi / 2 - shiStep / 2 + (selectedShiIndex + 0.5) * shiStep;
    final shiCellPosition = Offset(
      88 + cos(shiCellAngle) * 60,
      122 + sin(shiCellAngle) * 60,
    );
    expect(dialIndexAt(shiCellPosition, 12), selectedShiIndex);
    await tester.tapAt(tester.getTopLeft(thirdSmallDial) + shiCellPosition);
    await tester.pumpAndSettle();

    final selectedShiPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<TwelveSegmentDialPainter>()
        .single;
    expect(selectedShiPainter.currentIndex, selectedShiIndex);
    expect(selectedShiPainter.startYear, selectedShiYear);

    await tester.ensureVisible(mobileHexagramTab);
    await tester.tap(mobileHexagramTab);
    await tester.pumpAndSettle();
    final selectedShiHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(selectedShiHexagramPainter.currentYear, selectedShiYear);

    final selectedYunDial = find.byKey(const ValueKey('second_small_dial'));
    await tester.ensureVisible(selectedYunDial);
    final selectedYunDate = DateTime(selectedShiYear);
    final currentYunNumber = ClockCalculations.yunNumber(selectedYunDate);
    final currentYunIndex = ClockCalculations.yunIndex(selectedYunDate);
    final firstYunNumber = currentYunNumber - currentYunIndex;
    final selectedYunIndex = (currentYunIndex + 1) % 30;
    final selectedYunNumber = firstYunNumber + selectedYunIndex;
    final selectedYunYear = ClockCalculations.yunStartYear(selectedYunNumber);
    const yunStep = 2 * pi / 30;
    final yunCellAngle =
        pi / 2 - yunStep / 2 + (selectedYunIndex + 0.5) * yunStep;
    final yunCellPosition = Offset(
      88 + cos(yunCellAngle) * 60,
      122 + sin(yunCellAngle) * 60,
    );
    expect(dialIndexAt(yunCellPosition, 30), selectedYunIndex);
    await tester.tapAt(tester.getTopLeft(selectedYunDial) + yunCellPosition);
    await tester.pumpAndSettle();

    final selectedYunPainter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: selectedYunDial,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as ThirtySegmentDialPainter;
    expect(selectedYunPainter.currentIndex, selectedYunIndex);
    expect(selectedYunPainter.labels[selectedYunIndex], '$selectedYunNumber');
    final selectedYunHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(selectedYunHexagramPainter.currentYear, selectedYunYear);
    await tester.pump(const Duration(seconds: 1));
    final refreshedYunHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(refreshedYunHexagramPainter.currentYear, selectedYunYear);

    final selectedHuiDial = find.byKey(const ValueKey('first_small_dial'));
    await tester.ensureVisible(selectedHuiDial);
    final currentHuiDate = DateTime(selectedYunYear);
    final currentHuiIndex = ClockCalculations.huiIndex(currentHuiDate);
    final selectedHuiIndex = (currentHuiIndex + 1) % 12;
    final selectedHuiNumber =
        ClockCalculations.huiNumber(currentHuiDate) +
        selectedHuiIndex -
        currentHuiIndex;
    final selectedHuiYear = ClockCalculations.huiStartYear(selectedHuiNumber);
    const huiStep = 2 * pi / 12;
    final huiCellAngle =
        pi / 2 - huiStep / 2 + (selectedHuiIndex + 0.5) * huiStep;
    final huiCellPosition = Offset(
      88 + cos(huiCellAngle) * 60,
      122 + sin(huiCellAngle) * 60,
    );
    expect(dialIndexAt(huiCellPosition, 12), selectedHuiIndex);
    await tester.tapAt(tester.getTopLeft(selectedHuiDial) + huiCellPosition);
    await tester.pumpAndSettle();

    final selectedHuiPainter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: selectedHuiDial,
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter
            as BranchPlaceholderPainter;
    expect(selectedHuiPainter.currentIndex, selectedHuiIndex);
    final selectedHuiHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(selectedHuiHexagramPainter.currentYear, selectedHuiYear);

    final mobileThemeButton = find.byIcon(Icons.palette_outlined);
    await tester.ensureVisible(mobileThemeButton);
    await tester.tap(mobileThemeButton);
    await tester.pumpAndSettle();
    expect(find.text('mobileOptimized Light'), findsOneWidget);
    expect(find.text('Chronicle Indigo Light'), findsNothing);
  });

  testWidgets('shows only desktop themes on wide layouts', (tester) async {
    await pumpClockApp(tester, viewportSize: const Size(1000, 900));

    final clockPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<ClockPainter>()
        .single;
    expect(clockPainter.visibleRings, contains(ClockDialRing.months));
    expect(clockPainter.visibleRings, contains(ClockDialRing.weeks));
    expect(clockPainter.visibleRings, contains(ClockDialRing.days));
    expect(clockPainter.visibleRings, contains(ClockDialRing.seconds));
    expect(clockPainter.visibleRings, contains(ClockDialRing.meridians));
    expect(clockPainter.hourRingFontSize, 20);
    expect(clockPainter.currentHourRingFontSize, 22);
    expect(clockPainter.hourBaseFactor, ClockRadiusFactors.hourBase);
    expect(clockPainter.protectionRayReachFactor, 1.41421356237);
    expect(clockPainter.rotatingGeneralFontSize, 16);
    expect(clockPainter.rotatingBranchFontSize, 12);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('main_dial_caption')))
          .style
          ?.fontSize,
      22,
    );

    final desktopHexagramTab = find.text('Hexagram dial');
    await tester.ensureVisible(desktopHexagramTab);
    await tester.tap(desktopHexagramTab);
    await tester.pumpAndSettle();
    final desktopHexagramPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HexagramDialPlaceholderPainter>()
        .single;
    expect(desktopHexagramPainter.fontScale, 1);

    final themeButton = find.byIcon(Icons.palette_outlined);
    await tester.ensureVisible(themeButton);
    await tester.tap(themeButton);
    await tester.pumpAndSettle();
    expect(find.text('Chronicle Indigo Light'), findsOneWidget);
    expect(find.text('mobileOptimized Light'), findsNothing);
  });
}
