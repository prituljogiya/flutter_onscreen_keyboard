import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/numeric_keyboard_controller.dart';
import 'package:flutter_onscreen_keyboard/core/numeric_range.dart';

void main() {
  group('NumericKeyboardController', () {
    late TextEditingController textController;
    late FocusNode focusNode;
    late NumericKeyboardController c;

    String? validateRange(String value) {
      final n = int.tryParse(value);
      if (n == null) return 'Enter a number';
      if (n < 1) return 'Must be >= 1';
      if (n > 200) return 'Must be <= 200';
      return null;
    }

    setUp(() {
      textController = TextEditingController();
      focusNode = FocusNode();
      c = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        validator: validateRange,
      );
    });

    tearDown(() {
      c.dispose();
      textController.dispose();
      focusNode.dispose();
    });

    test('empty preview does not show error until user types', () {
      expect(textController.text, isEmpty);
      expect(c.validationError, isNull);
      textController.text = '201';
      expect(c.validationError, isNull);
    });

    test('shows range error after user types out of range', () {
      for (final digit in ['2', '0', '1']) {
        c.insertDigit(digit);
      }
      expect(c.validationError, 'Must be <= 200');
    });

    test('clearValidation resets edit state', () {
      for (final digit in ['2', '0', '1']) {
        c.insertDigit(digit);
      }
      expect(c.validationError, isNotNull);

      c.clearValidation();
      expect(c.validationError, isNull);
      textController.text = '201';
      expect(c.validationError, isNull);
    });

    test('enter blocks empty without min or max', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
      );
      expect(c2.enter(strictValidator: (v) => NumericRange.validate(
            v,
            allowIncomplete: false,
          )), isFalse);
      expect(c2.validationError, 'Enter a number');
      c2.dispose();
    });

    test('enter always validates even without prior typing', () {
      expect(c.enter(strictValidator: (v) => NumericRange.validate(
            v,
            allowIncomplete: false,
          )), isFalse);
      expect(c.validationError, 'Enter a number');

      textController.text = '201';
      expect(c.enter(), isFalse);
      expect(c.validationError, 'Must be <= 200');
    });

    test('insertDecimal is ignored when decimal input is disabled', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        allowDecimalInput: false,
      );
      expect(c2.insertDecimal(), isFalse);
      expect(textController.text, isEmpty);
      c2.dispose();
    });

    test('clear resets to empty preview', () {
      c.insertDigit('5');
      c.clear();
      expect(textController.text, isEmpty);
    });

    test('insertDigit stops at maxLength', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        maxLength: 4,
      );
      for (final d in ['1', '2', '3', '4']) {
        c2.insertDigit(d);
      }
      expect(textController.text, '1234');
      c2.insertDigit('5');
      expect(textController.text, '1234');
      c2.dispose();
    });

    test(
        'insertDigit lets the user type > max within the digit cap; '
        'extra digits beyond max width are silently rejected',
        () {
      // max=59 → 2-digit cap. The user can still type "99" so the live
      // validator can flash "Must be <= 59". A 3rd digit would exceed the
      // digit-count cap and is silently rejected.
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        maxValue: 59,
        integersOnly: true,
        validator: (v) => NumericRange.validate(v, max: 59, integersOnly: true),
      );
      c2.insertDigit('9');
      c2.insertDigit('9');
      expect(textController.text, '99');
      expect(c2.validationError, 'Must be <= 59');
      // 3rd digit would exceed the 2-digit cap → silently rejected.
      c2.insertDigit('9');
      expect(textController.text, '99');
      expect(c2.validationError, 'Must be <= 59');
      c2.backspace();
      expect(textController.text, '9');
      expect(c2.validationError, isNull);
      c2.dispose();
    });

    test('insertDigit allows decimal when min needs fractional digits', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        minValue: 0.5,
        maxValue: 500,
      );
      c2.insertDigit('0');
      c2.insertDecimal();
      c2.insertDigit('6');
      expect(textController.text, '0.6');
      c2.dispose();
    });

    test('incomplete decimal does not show error while typing', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        validator: (v) => NumericRange.validate(v, min: 3.1, max: 5.5),
        allowDecimalInput: true,
      );
      c2.insertDigit('3');
      c2.insertDecimal();
      expect(c2.validationError, isNull);
      expect(
        c2.enter(
          strictValidator: (v) => NumericRange.validate(
            v,
            min: 3.1,
            max: 5.5,
            allowIncomplete: false,
          ),
        ),
        isFalse,
      );
      expect(c2.validationError, 'Must be >= 3.1');
      c2.dispose();
    });

    test('whitespace-only validation is treated as no error', () {
      final c2 = NumericKeyboardController(
        textController: textController,
        focusNode: focusNode,
        validator: (_) => '   ',
      );
      c2.insertDigit('1');
      expect(c2.validationError, isNull);
      c2.dispose();
    });
  });
}
