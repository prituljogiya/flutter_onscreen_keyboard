import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'keyboard_key_timing.dart';

import 'text_editing_controller_guard.dart';

class KeyboardController extends GetxController {
  TextEditingController textController;
  final FocusNode focusNode;
  /// Preview strip focus (cursor). May be set after [Get.find] if the controller
  /// was created without it.
  FocusNode? previewFocusNode;
  final VoidCallback? onEnterPressed;
  String? Function(String)? validator;

  int? maxLength;

  /// Minimum character count before [enter] succeeds (shown on the keyboard
  /// panel when set on [CustomKeyboard]).
  int? minLength;

  final RxBool _isShiftActive = false.obs;
  final RxBool _isCapsLock = false.obs;
  /// Single Caps tap: uppercase without highlighting Shift.
  final RxBool _capsOneShot = false.obs;
  final RxBool _isNumericMode = false.obs;

  static const Duration _capsDoubleTapWindow = Duration(milliseconds: 400);
  DateTime? _lastCapsTap;
  final RxBool _isSymbolsMode = false.obs;
  final RxBool _isEmojiMode = false.obs;
  final RxnString _validationError = RxnString();
  final RxBool _showValidationError = false.obs;
  final RxnString _flashKeyId = RxnString();

  Timer? _flashTimer;
  bool _active = true;

  bool get isActive => _active;
  bool get _canEdit =>
      _active && isTextEditingControllerUsable(textController);

  bool get isShiftActive => _isShiftActive.value;
  bool get isCapsLock => _isCapsLock.value;
  bool get isCapsOneShot => _capsOneShot.value;
  bool get isNumericMode => _isNumericMode.value;

  /// For [Obx] / [GetBuilder] so modifier keys repaint when shift/caps changes.
  RxBool get isShiftActiveRx => _isShiftActive;
  RxBool get isCapsLockRx => _isCapsLock;
  RxBool get capsOneShotRx => _capsOneShot;

  bool get isCapsMode => _capsOneShot.value || _isCapsLock.value;

  /// Letter keys use uppercase layout when true (standard shift / caps-lock rules).
  bool get isUppercase {
    if (_isCapsLock.value) {
      return !_isShiftActive.value;
    }
    return _isShiftActive.value || _capsOneShot.value;
  }
  bool get isSymbolsMode => _isSymbolsMode.value;
  bool get isEmojiMode => _isEmojiMode.value;
  String? get validationError => _validationError.value;

  /// True only after Enter failed (not while typing).
  bool get shouldShowValidationError =>
      _showValidationError.value && _validationError.value != null;

  RxBool get showValidationErrorRx => _showValidationError;

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

  void rebind({
    required TextEditingController textController,
    FocusNode? previewFocusNode,
    String? Function(String)? validator,
    int? maxLength,
    int? minLength,
  }) {
    if (!identical(this.textController, textController)) {
      if (isTextEditingControllerUsable(this.textController)) {
        this.textController.removeListener(_onTextChanged);
      }
      this.textController = textController;
      textController.addListener(_onTextChanged);
    }
    if (previewFocusNode != null) {
      this.previewFocusNode = previewFocusNode;
    }
    this.validator = validator;
    this.maxLength = maxLength;
    this.minLength = minLength;
    _active = true;
    clearValidation();
  }

  @override
  void onClose() {
    _active = false;
    _flashTimer?.cancel();
    if (isTextEditingControllerUsable(textController)) {
      textController.removeListener(_onTextChanged);
    }
    super.onClose();
  }

  void flashKey(String keyId) {
    _flashKeyId.value = keyId;
    _flashTimer?.cancel();
    _flashTimer = Timer(KeyboardKeyTiming.flashHighlight, () {
      _flashKeyId.value = null;
    });
  }

  /// Number-row dual keys (e.g. `1|!`): symbol vs digit — [Shift] only, not Caps.
  bool get useTopCharacterOnDualKey => _isShiftActive.value;

  void moveCursor(int delta) {
    if (!_canEdit) return;
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
    if (!_canEdit || text.isEmpty) return;

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

    // Shift is one-shot; Caps stays until the user taps Caps again (or Caps lock off).
    if (_isShiftActive.value) {
      _isShiftActive.value = false;
    }
  }

  void backspace() {
    if (!_canEdit) return;
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
    if (!_canEdit) return;
    final offset = caretOffset.clamp(0, text.length);
    textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  bool enter() {
    if (!_canEdit) return false;
    final error = _computeEnterError();
    if (error != null) {
      _validationError.value = error;
      _showValidationError.value = true;
      return false;
    }
    clearValidation();

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

    // Caps on + Shift → caps lock with both keys lit; layout inverts via Shift.
    if (_capsOneShot.value && !_isCapsLock.value) {
      _capsOneShot.value = false;
      _isCapsLock.value = true;
      _isShiftActive.value = true;
      return;
    }

    if (_isCapsLock.value) {
      _isShiftActive.value = !_isShiftActive.value;
      return;
    }

    _isShiftActive.value = !_isShiftActive.value;
  }

  /// Caps: single tap toggles all-letter uppercase (Caps lit, Shift not lit).
  /// Stays on while typing until Caps is tapped again.
  /// Shift while Caps is on upgrades to caps lock (both keys can stay lit).
  /// Double tap within [_capsDoubleTapWindow] turns caps lock on (Shift off).
  /// Tap Caps again while locked (or one-shot on) turns caps off.
  void onCapsKeyPressed() {
    final now = DateTime.now();

    if (_isCapsLock.value) {
      _isCapsLock.value = false;
      _isShiftActive.value = false;
      _capsOneShot.value = false;
      _lastCapsTap = null;
      return;
    }

    if (_lastCapsTap != null &&
        now.difference(_lastCapsTap!) <= _capsDoubleTapWindow) {
      _lastCapsTap = null;
      _isShiftActive.value = false;
      _capsOneShot.value = false;
      _isCapsLock.value = true;
      return;
    }

    _lastCapsTap = now;
    final turningOff = _capsOneShot.value;
    _isShiftActive.value = false;
    _capsOneShot.value = !turningOff;
    if (turningOff) {
      _isShiftActive.value = false;
    }
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
    if (!_canEdit) return;
    textController.clear();
    clearValidation();
  }

  void clearValidation() {
    _validationError.value = null;
    _showValidationError.value = false;
  }

  void validateNow() => clearValidation();

  String? _computeEnterError() {
    if (!_canEdit) return null;
    final value = textController.text;
    if (minLength != null && value.length < minLength!) {
      return 'At least $minLength characters';
    }
    if (validator != null) {
      return validator!(value);
    }
    return null;
  }

  void _onTextChanged() {}

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
