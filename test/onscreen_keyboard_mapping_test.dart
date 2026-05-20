import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/onscreen_keyboard_mapping.dart';

void main() {
  group('preferOnscreenNumericKeyboard', () {
    test('numeric types use numeric keyboard', () {
      expect(preferOnscreenNumericKeyboard(TextInputType.number), isTrue);
      expect(preferOnscreenNumericKeyboard(TextInputType.phone), isTrue);
      expect(
        preferOnscreenNumericKeyboard(
          const TextInputType.numberWithOptions(decimal: true),
        ),
        isTrue,
      );
    });

    test('text types use custom alpha keyboard', () {
      expect(preferOnscreenNumericKeyboard(TextInputType.text), isFalse);
      expect(
        preferOnscreenNumericKeyboard(TextInputType.emailAddress),
        isFalse,
      );
      expect(preferOnscreenNumericKeyboard(TextInputType.multiline), isFalse);
      expect(preferOnscreenNumericKeyboard(TextInputType.name), isFalse);
    });
  });

  group('integersOnlyKeyboardType', () {
    test('integer number types use whole-number validation', () {
      expect(integersOnlyKeyboardType(TextInputType.number), isTrue);
      expect(
        integersOnlyKeyboardType(const TextInputType.numberWithOptions()),
        isTrue,
      );
      expect(integersOnlyKeyboardType(TextInputType.phone), isFalse);
    });

    test('decimal numberWithOptions allows fractions', () {
      expect(
        integersOnlyKeyboardType(
          const TextInputType.numberWithOptions(decimal: true),
        ),
        isFalse,
      );
    });
  });
}
