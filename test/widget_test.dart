import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';

void main() {
  testWidgets('shows app version', (tester) async {
    await tester.pumpWidget(const ClockApp());
    await tester.pump();

    expect(find.textContaining('1.0.1'), findsOneWidget);
  });

  testWidgets('can collapse the left dial column', (tester) async {
    await tester.pumpWidget(const ClockApp());
    await tester.pump();

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
    await tester.pumpWidget(const ClockApp());
    await tester.pump();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeast(4));
  });
}
