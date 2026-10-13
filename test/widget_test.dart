import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/clock_painter.dart';
import 'package:flutter_application_1/dial_painters.dart';
import 'package:flutter_application_1/models/clock_models.dart';

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
