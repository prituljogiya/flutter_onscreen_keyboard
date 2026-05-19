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
  });
}
