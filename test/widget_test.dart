import 'package:chordflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ChordFlow opent',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ChordFlowApp(
          initialThemeMode: ThemeMode.system,
        ),
      );

      expect(
        find.text('ChordFlow'),
        findsOneWidget,
      );
    },
  );
}
