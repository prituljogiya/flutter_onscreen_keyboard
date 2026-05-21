import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

void main() {
  group('NumericRange', () {
    test('validates integer bounds', () {
      expect(NumericRange.validate('25', min: 18, max: 60), isNull);
      expect(NumericRange.validate('17', min: 18, max: 60), 'Must be >= 18');
      expect(NumericRange.validate('61', min: 18, max: 60), 'Must be <= 60');
    });

    test('validates decimal bounds', () {
      expect(NumericRange.validate('4.2', min: 3.1, max: 5.5), isNull);
      expect(NumericRange.validate('3.0', min: 3.1, max: 5.5), 'Must be >= 3.1');
      expect(NumericRange.validate('5.6', min: 3.1, max: 5.5), 'Must be <= 5.5');
    });

    test('formatBound trims trailing zeros', () {
      expect(NumericRange.formatBound(3.1), '3.1');
      expect(NumericRange.formatBound(5.5), '5.5');
      expect(NumericRange.formatBound(18), '18');
    });

    test('integersOnly accepts whole-number decimals and defers trailing dot', () {
      expect(
        NumericRange.validate('1', min: 1, max: 200, integersOnly: true),
        isNull,
      );
      expect(
        NumericRange.validate('1.0', min: 1, max: 200, integersOnly: true),
        isNull,
      );
      expect(
        NumericRange.validate('25.', min: 18, max: 60, integersOnly: true),
        isNull,
      );
      expect(
        NumericRange.validate('1.5', min: 1, max: 200, integersOnly: true),
        'Whole numbers only',
      );
    });

    test('integersOnly shows whole-number error before range for 2.2 on age', () {
      expect(
        NumericRange.validate('2.2', min: 18, max: 60, integersOnly: true),
        'Whole numbers only',
      );
      expect(
        NumericRange.validate('2.2', min: 18, max: 60, integersOnly: true),
        isNot('Must be >= 18'),
      );
    });

    test('commitText normalizes integer staging', () {
      expect(NumericRange.commitText('1.0', integersOnly: true), '1');
      expect(NumericRange.commitText('10.0', integersOnly: true), '10');
      expect(NumericRange.commitText('4.2', integersOnly: false), '4.2');
    });

    test('validate empty when bounds are set', () {
      expect(
        NumericRange.validate('', min: 18, max: 60),
        'Enter a number',
      );
    });

    test('validate empty on Enter without bounds', () {
      expect(
        NumericRange.validate('', allowIncomplete: false),
        'Enter a number',
      );
    });

    test('canAcceptDigit respects maxLength', () {
      expect(
        NumericRange.canAcceptDigit(
          currentText: '1234',
          digit: '5',
          maxLength: 4,
        ),
        isFalse,
      );
    });

    test('canAcceptDigit from zero replaces leading zero', () {
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0',
          digit: '7',
          maxLength: 4,
        ),
        isTrue,
      );
    });

    test('canAcceptDigit blocks extra whole digits for max 59', () {
      expect(
        NumericRange.canAcceptDigit(
          currentText: '59',
          digit: '9',
          max: 59,
          integersOnly: true,
        ),
        isFalse,
      );
    });

    test('canAcceptDigit allows 0.6 when min is 0.5 and max is 500', () {
      expect(
        NumericRange.fractionalDigitsForRange(min: 0.5, max: 500),
        1,
      );
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0.',
          digit: '6',
          min: 0.5,
          max: 500,
        ),
        isTrue,
      );
      expect(
        NumericRange.validate('0.6', min: 0.5, max: 500),
        isNull,
      );
    });

    test('defers validation while decimal is incomplete', () {
      expect(
        NumericRange.validate('3.', min: 3.1, max: 5.5, allowIncomplete: true),
        isNull,
      );
      expect(
        NumericRange.validate('3.', min: 3.1, max: 5.5, allowIncomplete: false),
        'Must be >= 3.1',
      );
    });
  });
}
