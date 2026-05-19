import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/keyboard_controller.dart';
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
  }) {
    return KeyboardController(
      textController: text ?? TextEditingController(),
      focusNode: FocusNode(),
      minLength: minLength,
      maxLength: maxLength,
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
  });

  group('Caps / shift', () {
    test('single caps highlights caps mode not shift', () {
      final c = newController();
      c.onCapsKeyPressed();
      expect(c.isCapsOneShot, isTrue);
      expect(c.isShiftActive, isFalse);
      expect(c.isCapsLock, isFalse);
      expect(c.isUppercase, isTrue);

      c.toggleShift();
      expect(c.isShiftActive, isTrue);
      expect(c.isCapsOneShot, isFalse);
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
