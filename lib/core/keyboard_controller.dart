import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeyboardController extends GetxController {
  final TextEditingController textController;
  final FocusNode focusNode;
  /// Preview strip focus (cursor). May be set after [Get.find] if the controller
  /// was created without it.
  FocusNode? previewFocusNode;
  final VoidCallback? onEnterPressed;
  final String? Function(String)? validator;

  int? maxLength;

  /// Minimum character count before [enter] succeeds (shown on the keyboard
  /// panel when set on [CustomKeyboard]).
  int? minLength;

  final RxBool _isShiftActive = false.obs;
  final RxBool _isCapsLock = false.obs;
  final RxBool _isNumericMode = false.obs;

  static const Duration _capsDoubleTapWindow = Duration(milliseconds: 400);
  DateTime? _lastCapsTap;
  final RxBool _isSymbolsMode = false.obs;
  final RxBool _isEmojiMode = false.obs;
  final RxnString _validationError = RxnString();
  final RxnString _flashKeyId = RxnString();

  Timer? _flashTimer;

  bool get isShiftActive => _isShiftActive.value;
  bool get isCapsLock => _isCapsLock.value;
  bool get isNumericMode => _isNumericMode.value;

  /// For [Obx] / [GetBuilder] so modifier keys repaint when shift/caps changes.
  RxBool get isShiftActiveRx => _isShiftActive;
  RxBool get isCapsLockRx => _isCapsLock;

  /// Letter keys use uppercase layout when true (standard shift / caps-lock rules).
  bool get isUppercase =>
      _isCapsLock.value ? !_isShiftActive.value : _isShiftActive.value;
  bool get isSymbolsMode => _isSymbolsMode.value;
  bool get isEmojiMode => _isEmojiMode.value;
  String? get validationError => _validationError.value;
  String? get flashKeyId => _flashKeyId.value;

  RxnString get flashKeyRx => _flashKeyId;
  String get text => textController.text;

  KeyboardController({
    required this.textController,
    required this.focusNode,
    this.previewFocusNode,
    this.onEnterPressed,
    this.validator,
    this.maxLength,
    this.minLength,
  }) {
    textController.addListener(_onTextChanged);
  }

  @override
  void onClose() {
    _flashTimer?.cancel();
    textController.removeListener(_onTextChanged);
    super.onClose();
  }

  void flashKey(String keyId) {
    _flashKeyId.value = keyId;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 220), () {
      _flashKeyId.value = null;
    });
  }

  /// Number-row dual keys (e.g. `1|!`): symbols on top, digits on bottom.
  /// Top symbol is used only while [isShiftActive] (same as a default keyboard).
  bool get useTopCharacterOnDualKey => _isShiftActive.value;

  void moveCursor(int delta) {
    final text = textController.text;
    var selection = textController.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    final base = selection.baseOffset;
    final next = (base + delta).clamp(0, text.length);
    if (next == base) return;
    _applyEditingValue(text, next);
  }

  void insertText(String text) {
    if (text.isEmpty) return;

    final currentText = textController.text;
    var selection = textController.selection;

    final String newText;
    final int newSelectionOffset;

    if (!selection.isValid) {
      newText = currentText + text;
      newSelectionOffset = newText.length;
    } else {
      newText = currentText.replaceRange(selection.start, selection.end, text);
      newSelectionOffset = selection.start + text.length;
    }

    final limit = maxLength;
    if (limit != null && newText.length > limit) {
      return;
    }

    _applyEditingValue(newText, newSelectionOffset);

    if (_isShiftActive.value) {
      _isShiftActive.value = false;
    }
  }

  void backspace() {
    final currentText = textController.text;
    var selection = textController.selection;

    if (!selection.isValid) {
      if (currentText.isEmpty) return;
      selection = TextSelection.collapsed(offset: currentText.length);
    }

    if (selection.start == 0 && selection.end == 0) {
      return;
    }

    if (selection.start != selection.end) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      _applyEditingValue(newText, selection.start);
    } else if (selection.start > 0) {
      final newText = currentText.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      _applyEditingValue(newText, selection.start - 1);
    }
  }

  /// Applies text + caret in one [TextEditingValue] so the preview [TextField]
  /// keeps a visible caret (separate `.text` / `.selection` updates can hide it).
  void _applyEditingValue(String text, int caretOffset) {
    final offset = caretOffset.clamp(0, text.length);
    textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
    _validate();
  }

  bool enter() {
    _validate();
    if (_validationError.value != null) {
      return false;
    }

    onEnterPressed?.call();
    previewFocusNode?.unfocus();
    focusNode.unfocus();
    return true;
  }

  /// Dismisses the keyboard only: unfocuses the field and preview. Does not
  /// clear text, validation, or caps/shift state.
  bool closeKeyboard() {
    previewFocusNode?.unfocus();
    focusNode.unfocus();

    return true;
  }

  void insertSpace() => insertText(' ');

  void toggleShift() {
    _lastCapsTap = null;
    _isShiftActive.value = !_isShiftActive.value;
  }

  /// Caps: single tap toggles shift (one capital / symbol row like Shift).
  /// Double tap within [_capsDoubleTapWindow] turns caps lock on.
  /// Tap again while locked turns caps lock off and returns to lowercase.
  void onCapsKeyPressed() {
    final now = DateTime.now();

    if (_isCapsLock.value) {
      _isCapsLock.value = false;
      _isShiftActive.value = false;
      _lastCapsTap = null;
      return;
    }

    if (_lastCapsTap != null &&
        now.difference(_lastCapsTap!) <= _capsDoubleTapWindow) {
      _lastCapsTap = null;
      _isShiftActive.value = false;
      _isCapsLock.value = true;
      return;
    }

    _lastCapsTap = now;
    _isShiftActive.value = !_isShiftActive.value;
  }

  void toggleNumeric() {
    _isNumericMode.value = !_isNumericMode.value;
    _isSymbolsMode.value = false;
    _isEmojiMode.value = false;
  }

  void toggleSymbols() {
    _isSymbolsMode.value = !_isSymbolsMode.value;
  }

  void switchToAlpha() {
    _isNumericMode.value = false;
    _isSymbolsMode.value = false;
    _isEmojiMode.value = false;
  }

  void clear() {
    textController.clear();
    _validationError.value = null;
  }

  /// Re-runs validation (e.g. when [minLength] / rules change on the widget).
  void validateNow() => _validate();

  void _validate() {
    final value = textController.text;
    String? error;

    if (minLength != null && value.length < minLength!) {
      error = 'At least $minLength characters';
    }

    if (error == null && validator != null) {
      error = validator!(value);
    }

    _validationError.value = error;
  }

  void _onTextChanged() => _validate();

  List<List<String>> get currentLayout {
    return isUppercase
        ? KeyboardConstants.qwertyUpperLayout
        : KeyboardConstants.qwertyLayout;
  }
}

class KeyboardConstants {
  static const List<List<String>> qwertyLayout = [
    [
      '~|`',
      '1|!',
      '2|@',
      '3|#',
      '4|\$',
      '5|%',
      '6|^',
      '7|&',
      '8|*',
      '9|(',
      '0|)',
      '-|_',
      '=|+',
      'BACKSPACE',
    ],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', r'\'],
    ['CAPS', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '"'],
    [
      'SHIFT',
      'z',
      'x',
      'c',
      'v',
      'b',
      'n',
      'm',
      ',',
      '.',
      '/',
      'LEFT ARROW',
      'RIGHT ARROW',
    ],
    ['SPACE', 'ENTER'],
  ];

  static const List<List<String>> qwertyUpperLayout = [
    [
      '~|`',
      '1|!',
      '2|@',
      '3|#',
      '4|\$',
      '5|%',
      '6|^',
      '7|&',
      '8|*',
      '9|(',
      '0|)',
      '-|_',
      '=|+',
      'BACKSPACE',
    ],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', r'\'],
    ['CAPS', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '"'],
    [
      'SHIFT',
      'Z',
      'X',
      'C',
      'V',
      'B',
      'N',
      'M',
      ',',
      '.',
      '/',
      'LEFT ARROW',
      'RIGHT ARROW',
    ],
    ['SPACE', 'ENTER'],
  ];
}
