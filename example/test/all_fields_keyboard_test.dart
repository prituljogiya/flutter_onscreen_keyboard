import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

import 'test_harness.dart';

void main() {
  group('Custom keyboard fields (alpha)', () {
    setUp(() => configureKeyboardTests(useCustomKeyboard: true));
    tearDown(tearDownKeyboardTests);

    void bindViewport(WidgetTester tester) {
      addTearDown(() => resetTestViewport(tester));
    }

    testWidgets('Name opens QWERTY and commits on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_name');

      expect(find.byKey(customKeyboardPreviewKey), findsOneWidget);
      expect(find.byType(CustomKeyboard), findsOneWidget);
      expect(find.byType(NumericKeyboard), findsNothing);

      await typeAlpha(tester, 'ann');
      await tapEnter(tester);

      expect(find.byKey(customKeyboardPreviewKey), findsNothing);
      expect(fieldText(tester, 'field_name'), 'ann');
    });

    testWidgets('Name close button dismisses keyboard', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_name');
      expect(find.byType(CustomKeyboard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(find.byType(CustomKeyboard), findsNothing);
      expect(find.byKey(customKeyboardPreviewKey), findsNothing);
    });

    testWidgets('Name blocks Enter below min length', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_name');
      await typeAlpha(tester, 'ab');
      expect(find.text('At least 3 characters'), findsNothing);

      await tapEnter(tester);
      expect(find.text('At least 3 characters'), findsOneWidget);
      expect(fieldText(tester, 'field_name'), isEmpty);
    });

    testWidgets('Email opens QWERTY and commits text', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_email');

      expect(find.byType(CustomKeyboard), findsOneWidget);
      await typeAlpha(tester, 'a');
      await tapKeyLabel(tester, 't');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_email'), 'at');
    });

    testWidgets('Memo opens QWERTY and commits text', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_memo');

      expect(find.byType(CustomKeyboard), findsOneWidget);
      await typeAlpha(tester, 'hi');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_memo'), 'hi');
    });
  });

  group('Numeric keyboard fields', () {
    setUp(() => configureKeyboardTests(useCustomKeyboard: true));
    tearDown(tearDownKeyboardTests);

    void bindViewport(WidgetTester tester) {
      addTearDown(() => resetTestViewport(tester));
    }

    testWidgets('Age opens numeric pad with min/max hints', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');

      expect(find.byType(NumericKeyboard), findsOneWidget);
      expect(find.byType(CustomKeyboard), findsNothing);
      expect(find.text('Min Value'), findsOneWidget);
      expect(find.text('Max Value'), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
    });

    testWidgets('Age pressing decimal does not show error while typing', (
      tester,
    ) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');
      await typeDigits(tester, '2');
      await tapKeyLabel(tester, '.');
      expect(find.textContaining('Must be >='), findsNothing);
      expect(find.textContaining('Must be <='), findsNothing);
      expect(find.text('Whole numbers only'), findsNothing);
    });

    testWidgets('Age shows whole-number error for 2.2 not range error', (
      tester,
    ) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');
      await typeNumber(tester, '2.2');
      expect(find.text('Whole numbers only'), findsOneWidget);
      expect(find.textContaining('Must be >='), findsNothing);
    });

    testWidgets('Age close button dismisses keyboard', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');
      expect(find.byType(NumericKeyboard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(find.byType(NumericKeyboard), findsNothing);
    });

    testWidgets('Age commits in range on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');
      await typeDigits(tester, '25');
      await tapEnter(tester);

      expect(find.byType(NumericKeyboard), findsNothing);
      expect(fieldText(tester, 'field_age'), '25');
    });

    testWidgets('Quantity commits in range on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_quantity');
      await typeDigits(tester, '10');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_quantity'), '10');
    });

    testWidgets('Percent commits whole-number decimal as integer', (
      tester,
    ) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_percent');
      // Integer fields no longer show '.' — type 10 directly.
      await typeDigits(tester, '10');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_percent'), '10');
    });

    testWidgets('Quantity error clears when switching fields', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_quantity');
      await typeDigits(tester, '201');
      expect(find.text('Must be <= 200'), findsOneWidget);

      await tapField(tester, 'field_age');
      expect(find.text('Must be <= 200'), findsNothing);
    });

    testWidgets('Age shows no error until user types', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_age');
      expect(find.textContaining('Must be >='), findsNothing);
      expect(find.textContaining('Must be <='), findsNothing);
    });

    testWidgets('Access code validates 4 digits on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_pin');
      await typeDigits(tester, '123');
      await tapEnter(tester);

      expect(find.text('Use exactly 4 digits'), findsOneWidget);
      expect(fieldText(tester, 'field_pin'), isEmpty);

      await typeDigits(tester, '4');
      await tapEnter(tester);
      expect(fieldText(tester, 'field_pin'), '1234');
    });

    testWidgets('Amount commits in range on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_amount');
      await typeDigits(tester, '50');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_amount'), '50');
    });

    testWidgets('Age quantity and rating all show decimal key', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      for (final key in ['field_age', 'field_quantity', 'field_rating']) {
        await tapField(tester, key);
        expect(find.text('.'), findsOneWidget);
      }
    });

    testWidgets('Rating shows decimal bounds on keyboard', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_rating');

      expect(find.text('3.1'), findsOneWidget);
      expect(find.text('5.5'), findsOneWidget);
    });

    testWidgets('Rating does not error while typing incomplete decimal', (
      tester,
    ) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_rating');
      await typeDigits(tester, '3');
      await tapKeyLabel(tester, '.');
      expect(find.textContaining('Must be >='), findsNothing);
      expect(find.text('Enter a valid number'), findsNothing);
    });

    testWidgets('Rating commits decimal in range on Enter', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_rating');
      await typeNumber(tester, '4.2');
      await tapEnter(tester);

      expect(fieldText(tester, 'field_rating'), '4.2');
    });

    testWidgets('Rating rejects value above max while typing', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_rating');
      await typeNumber(tester, '6');
      expect(find.text('Must be <= 5.5'), findsOneWidget);
    });

    testWidgets('Rating rejects value below min while typing', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_rating');
      await typeNumber(tester, '2');
      expect(find.text('Must be >= 3.1'), findsOneWidget);
    });

    testWidgets('Phone has no min/max row', (tester) async {
      bindViewport(tester);
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_phone');
      expect(find.text('Min Value'), findsNothing);
      expect(find.text('Max Value'), findsNothing);
    });
  });

  group('Switching fields', () {
    setUp(() => configureKeyboardTests(useCustomKeyboard: true));
    tearDown(tearDownKeyboardTests);

    testWidgets('switches from alpha to numeric keyboard', (tester) async {
      addTearDown(() => resetTestViewport(tester));
      await pumpKeyboardDemo(tester);
      await tapField(tester, 'field_name');
      expect(find.byType(CustomKeyboard), findsOneWidget);

      await dismissOpenKeyboard(tester);
      await tapField(tester, 'field_age');
      expect(find.byType(NumericKeyboard), findsOneWidget);
      expect(find.byType(CustomKeyboard), findsNothing);
    });

    testWidgets('each field stays readOnly like default custom flow',
        (tester) async {
      addTearDown(() => resetTestViewport(tester));
      await pumpKeyboardDemo(tester);
      for (final key in [
        'field_name',
        'field_email',
        'field_memo',
        'field_username',
        'field_age',
        'field_quantity',
        'field_percent',
        'field_pin',
        'field_even',
        'field_rating',
        'field_amount',
        'field_weight',
        'field_phone',
        'field_zip',
      ]) {
        expect(readField(tester, key).readOnly, isTrue);
      }
    });
  });
}
