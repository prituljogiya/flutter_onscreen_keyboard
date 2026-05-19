import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/numericKeyController.dart';

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
      textController = TextEditingController(text: '0');
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

    test('seed value does not show error until user types', () {
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

    test('enter always validates even without prior typing', () {
      textController.text = '201';
      expect(c.enter(), isFalse);
      expect(c.validationError, 'Must be <= 200');
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
