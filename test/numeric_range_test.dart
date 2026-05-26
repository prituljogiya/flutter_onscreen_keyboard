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

    test('canAcceptDigit caps whole digits to width of max', () {
      // max: 59 → 2 whole digits allowed.
      // "5" + "9" → "59" (accepted, 2 digits).
      expect(
        NumericRange.canAcceptDigit(
          currentText: '5',
          digit: '9',
          max: 59,
          integersOnly: true,
        ),
        isTrue,
      );
      // "59" + "9" → "599" (3 digits > 2) → REJECTED silently.
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

    test(
        'canAcceptDigit lets the user type values > max within the digit cap',
        () {
      // Quantity 1-200: 3-digit cap. "999" is typeable so the live error
      // can show, but a 4th digit is silently rejected.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '99',
          digit: '9',
          min: 1,
          max: 200,
          integersOnly: true,
        ),
        isTrue,
      );
      expect(
        NumericRange.canAcceptDigit(
          currentText: '999',
          digit: '9',
          min: 1,
          max: 200,
          integersOnly: true,
        ),
        isFalse,
      );
      expect(
        NumericRange.validate('999', min: 1, max: 200, integersOnly: true),
        'Must be <= 200',
      );

      // Weight 0.5-500: 3-digit cap on whole part. "555" typeable, "5555" no.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '55',
          digit: '5',
          min: 0.5,
          max: 500,
        ),
        isTrue,
      );
      expect(
        NumericRange.canAcceptDigit(
          currentText: '555',
          digit: '5',
          min: 0.5,
          max: 500,
        ),
        isFalse,
      );
      expect(
        NumericRange.validate('555', min: 0.5, max: 500),
        'Must be <= 500',
      );
    });

    test('canAcceptDigit caps fractional digits when maxFractionDigits is set',
        () {
      // No bounds, but explicit cap of 1: "0.2" + "3" → reject.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0.2',
          digit: '3',
          maxFractionDigits: 1,
        ),
        isFalse,
      );

      // No bounds, no cap: anything goes (legacy behavior).
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0.2',
          digit: '3',
        ),
        isTrue,
      );

      // Explicit cap of 2 lets "12.34" through but rejects "12.345".
      expect(
        NumericRange.canAcceptDigit(
          currentText: '12.3',
          digit: '4',
          maxFractionDigits: 2,
        ),
        isTrue,
      );
      expect(
        NumericRange.canAcceptDigit(
          currentText: '12.34',
          digit: '5',
          maxFractionDigits: 2,
        ),
        isFalse,
      );

      // integersOnly wins over the cap (no `.` ever).
      expect(
        NumericRange.canAcceptDigit(
          currentText: '12',
          digit: '3',
          maxFractionDigits: 1,
          integersOnly: true,
        ),
        isTrue,
      );

      // min/max do not impose any implicit fractional cap. The user can
      // type as many digits after `.` as they want; only maxFractionDigits
      // gates it (and max enforces the numeric value).
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0.5',
          digit: '5',
          min: 0.5,
          max: 500,
          maxFractionDigits: 2,
        ),
        // 0.55 ≤ 500 and frac length 2 ≤ 2 → accepted.
        isTrue,
      );
      // No cap + bounds → still no fractional limit beyond the numeric max.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '0.123456',
          digit: '7',
          min: 0.5,
          max: 500,
        ),
        isTrue,
      );
    });

    test('canAcceptDigit allows in-progress typing that stays at or below max',
        () {
      // Trailing "." is treated as the integer part for the max comparison so
      // the user can still type "500." in a 0.5-500 weight field.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '500',
          digit: '.',
          min: 0.5,
          max: 500,
        ),
        isTrue,
      );
      // Same as above but for a tighter range; the user can still reach the
      // boundary value.
      expect(
        NumericRange.canAcceptDigit(
          currentText: '5.',
          digit: '5',
          min: 3.1,
          max: 5.5,
        ),
        isTrue,
      );
    });
  });
}
