import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/keyboard_controller.dart';
import 'package:flutter_onscreen_keyboard/core/onscreen_keyboard_validation.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  KeyboardController newController({
    TextEditingController? text,
    int? minLength,
    int? maxLength,
    String? Function(String)? validator,
  }) {
    return KeyboardController(
      textController: text ?? TextEditingController(),
      focusNode: FocusNode(),
      minLength: minLength,
      maxLength: maxLength,
      validator: validator,
    );
  }

  group('KeyboardController typing', () {
    test('insertText appends and clears shift', () {
      final text = TextEditingController();
      final c = newController(text: text);
      c.toggleShift();
      expect(c.isShiftActive, isTrue);

      c.insertText('a');
      expect(text.text, 'a');
      expect(c.isShiftActive, isFalse);
      c.onClose();
    });

    test('maxLength stops further input', () {
      final text = TextEditingController();
      final c = newController(text: text, maxLength: 3);
      c.insertText('abcd');
      expect(text.text, isEmpty);
      c.onClose();
    });

    test('minLength validates on Enter only', () {
      final text = TextEditingController();
      final c = newController(text: text, minLength: 3);
      c.insertText('ab');
      expect(c.shouldShowValidationError, isFalse);

      expect(c.enter(), isFalse);
      expect(c.shouldShowValidationError, isTrue);
      expect(c.validationError, 'At least 3 characters');

      c.clearValidation();
      c.insertText('c');
      expect(c.enter(), isTrue);
      c.onClose();
    });

    test('empty value blocks Enter and keeps validation visible', () {
      final text = TextEditingController();
      final c = newController(text: text);
      expect(c.enter(), isFalse);
      expect(c.shouldShowValidationError, isTrue);
      expect(c.validationError, 'Enter a value');
      c.onClose();
    });

    test('validator runs on Enter', () {
      final text = TextEditingController();
      final c = newController(
        text: text,
        validator: OnscreenKeyboardValidators.email,
      );
      c.insertText('bad');
      expect(c.enter(), isFalse);
      expect(c.validationError, 'Enter a valid email');

      c.clearValidation();
      c.insertText('user@example.com');
      expect(c.enter(), isTrue);
      c.onClose();
    });
  });

  group('Caps / shift', () {
    test('single caps highlights caps mode not shift', () {
      final c = newController();
      c.onCapsKeyPressed();
      expect(c.isCapsOneShot, isTrue);
      expect(c.isShiftActive, isFalse);
      expect(c.isCapsLock, isFalse);
      expect(c.isUppercase, isTrue);
      expect(c.isCapsMode, isTrue);
      c.onClose();
    });

    test('shift while caps one-shot enables caps lock with both lit', () {
      final c = newController();
      c.onCapsKeyPressed();
      c.toggleShift();
      expect(c.isCapsLock, isTrue);
      expect(c.isShiftActive, isTrue);
      expect(c.isCapsOneShot, isFalse);
      expect(c.isUppercase, isFalse);

      c.toggleShift();
      expect(c.isShiftActive, isFalse);
      expect(c.isUppercase, isTrue);
      c.onClose();
    });

    test('caps while shift active enables caps lock with both lit', () {
      final c = newController();
      c.toggleShift();
      expect(c.isShiftActive, isTrue);
      expect(c.isCapsLock, isFalse);

      c.onCapsKeyPressed();
      expect(c.isCapsLock, isTrue);
      expect(c.isShiftActive, isTrue);
      expect(c.isCapsOneShot, isFalse);
      expect(c.isUppercase, isFalse);
      c.onClose();
    });

    test('caps lock then shift toggles case same as shift then caps lock', () {
      final fromCapsFirst = newController();
      fromCapsFirst.onCapsKeyPressed();
      fromCapsFirst.toggleShift();

      final fromShiftFirst = newController();
      fromShiftFirst.toggleShift();
      fromShiftFirst.onCapsKeyPressed();

      expect(fromCapsFirst.isCapsLock, isTrue);
      expect(fromShiftFirst.isCapsLock, isTrue);
      expect(fromCapsFirst.isShiftActive, isTrue);
      expect(fromShiftFirst.isShiftActive, isTrue);
      expect(fromCapsFirst.isCapsOneShot, isFalse);
      expect(fromShiftFirst.isCapsOneShot, isFalse);
      expect(fromCapsFirst.isUppercase, isFalse);
      expect(fromShiftFirst.isUppercase, isFalse);

      fromCapsFirst.toggleShift();
      expect(fromCapsFirst.isShiftActive, isFalse);
      expect(fromCapsFirst.isUppercase, isTrue);

      fromCapsFirst.toggleShift();
      expect(fromCapsFirst.isShiftActive, isTrue);
      expect(fromCapsFirst.isUppercase, isFalse);

      fromCapsFirst.onClose();
      fromShiftFirst.onClose();
    });

    test('single caps keeps uppercase layout after typing', () async {
      final text = TextEditingController();
      final c = newController(text: text);
      c.onCapsKeyPressed();
      expect(c.isUppercase, isTrue);

      c.insertText('hello');
      expect(text.text, 'hello');
      expect(c.isCapsOneShot, isTrue);
      expect(c.isUppercase, isTrue);
      expect(c.currentLayout[1][0], 'Q');

      await Future<void>.delayed(const Duration(milliseconds: 450));
      c.onCapsKeyPressed();
      expect(c.isCapsOneShot, isFalse);
      expect(c.isUppercase, isFalse);
      c.onClose();
    });

    test('caps does not change dual key symbol selection', () {
      final c = newController();
      c.onCapsKeyPressed();
      expect(c.useTopCharacterOnDualKey, isFalse);

      c.onCapsKeyPressed();
      expect(c.isCapsLock, isTrue);
      expect(c.useTopCharacterOnDualKey, isFalse);

      c.toggleShift();
      expect(c.useTopCharacterOnDualKey, isTrue);
      c.toggleShift();
      expect(c.useTopCharacterOnDualKey, isFalse);
      c.onClose();
    });

    test('double tap caps enables caps lock', () {
      final c = newController();
      c.onCapsKeyPressed();
      expect(c.isShiftActive, isFalse);
      expect(c.isCapsOneShot, isTrue);

      c.onCapsKeyPressed();
      expect(c.isCapsLock, isTrue);
      expect(c.isShiftActive, isFalse);
      expect(c.isCapsOneShot, isFalse);
      expect(c.isUppercase, isTrue);

      c.onCapsKeyPressed();
      expect(c.isCapsLock, isFalse);
      expect(c.isUppercase, isFalse);
      c.onClose();
    });

    test('shift toggles uppercase layout', () {
      final c = newController();
      expect(c.isUppercase, isFalse);
      c.toggleShift();
      expect(c.isUppercase, isTrue);
      c.toggleShift();
      expect(c.isUppercase, isFalse);
      c.onClose();
    });
  });
}
