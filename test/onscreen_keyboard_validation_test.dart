import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/onscreen_keyboard_validation.dart';

void main() {
  group('OnscreenKeyboardValidators.email', () {
    test('accepts valid addresses', () {
      expect(OnscreenKeyboardValidators.email('user@example.com'), isNull);
      expect(
        OnscreenKeyboardValidators.email('name.last+tag@mail.co.uk'),
        isNull,
      );
    });

    test('rejects empty and invalid shapes', () {
      expect(OnscreenKeyboardValidators.email(''), 'Enter your email');
      expect(OnscreenKeyboardValidators.email('   '), 'Enter your email');
      expect(
        OnscreenKeyboardValidators.email('not-an-email'),
        'Enter a valid email',
      );
      expect(OnscreenKeyboardValidators.email('a@b'), 'Enter a valid email');
      expect(
        OnscreenKeyboardValidators.email('@example.com'),
        'Enter a valid email',
      );
      expect(OnscreenKeyboardValidators.email('user@'), 'Enter a valid email');
    });
  });
}
