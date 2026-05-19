import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

import 'test_harness.dart';

void main() {
  group('Keyboard demo smoke', () {
    setUp(() => configureKeyboardTests(useCustomKeyboard: true));
    tearDown(tearDownKeyboardTests);

    testWidgets('shows all form sections and field labels', (tester) async {
      addTearDown(() => resetTestViewport(tester));
      await pumpKeyboardDemo(tester);

      expect(find.text('On-screen Keyboard Demo'), findsOneWidget);
      expect(find.text('Showcase'), findsOneWidget);
      expect(find.text('Custom keyboard'), findsOneWidget);
      expect(find.text('Numeric — integers & range'), findsOneWidget);
      expect(find.text('Numeric — decimals & range'), findsOneWidget);
      expect(find.text('Rating (3.1 – 5.5)'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field_name')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field_email')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field_memo')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('field_username')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('field_age')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('field_quantity')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('field_percent')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('field_pin')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field_even')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('field_rating')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('field_amount')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('field_weight')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('field_phone')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field_zip')), findsOneWidget);
    });
  });

  group('System keyboard mode', () {
    setUp(() => configureKeyboardTests(useCustomKeyboard: false));
    tearDown(tearDownKeyboardTests);

    testWidgets('fields are editable with platform keyboard', (tester) async {
      addTearDown(() => resetTestViewport(tester));
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_name');

      expect(find.byKey(customKeyboardPreviewKey), findsNothing);
      expect(readField(tester, 'field_name').readOnly, isFalse);
      expect(find.byType(CustomKeyboard), findsNothing);
      expect(find.byType(NumericKeyboard), findsNothing);
    });
  });
}
