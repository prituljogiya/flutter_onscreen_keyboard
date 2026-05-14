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

  final RxBool _isShiftActive = false.obs;
  final RxBool _isCapsLock = false.obs;
  /// Second caps tap: uppercase + **symbol** row on dual keys (top character)
  /// until Caps cycles off. First caps tap is uppercase + **digit** row (bottom).
  /// Shift has no second level.
  final RxBool _capsExtended = false.obs;
  final RxBool _isNumericMode = false.obs;
  final RxBool _isSymbolsMode = false.obs;
  final RxBool _isEmojiMode = false.obs;
  final RxnString _validationError = RxnString();
  final RxnString _flashKeyId = RxnString();

  Timer? _flashTimer;

  bool get isShiftActive => _isShiftActive.value;
  bool get isCapsLock => _isCapsLock.value;
  bool get isCapsExtended => _capsExtended.value;
  bool get isNumericMode => _isNumericMode.value;
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

  /// Whether a tap on a dual key (e.g. `1|!`) should insert the top symbol.
  /// [Shift] → top. [Caps] once → bottom (digits). [Caps] twice → top (symbols).
  bool get useTopCharacterOnDualKey {
    if (_isShiftActive.value) return true;
    if (_isCapsLock.value && _capsExtended.value) return true;
    return false;
  }

  void moveCursor(int delta) {
    final text = textController.text;
    var selection = textController.selection;
    if (!selection.isValid) {
      final atEnd = text.length;
      textController.selection = TextSelection.collapsed(offset: atEnd);
      selection = textController.selection;
    }
    final base = selection.baseOffset;
    final next = (base + delta).clamp(0, text.length);
    if (next == base) return;
    textController.selection = TextSelection.collapsed(offset: next);
  }

  void insertText(String text) {
    if (text.isEmpty) return;

    final currentText = textController.text;
    final selection = textController.selection;

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

    textController.text = newText;
    textController.selection = TextSelection.collapsed(
      offset: newSelectionOffset,
    );

    if (_isShiftActive.value) {
      _isShiftActive.value = false;
    }
    _validate();
  }

  void backspace() {
    final currentText = textController.text;
    final selection = textController.selection;

    if (!selection.isValid || (selection.start == 0 && selection.end == 0)) {
      return;
    }

    if (selection.start != selection.end) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      textController.text = newText;
      textController.selection = TextSelection.collapsed(
        offset: selection.start,
      );
    } else if (selection.start > 0) {
      final newText = currentText.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      textController.text = newText;
      textController.selection = TextSelection.collapsed(
        offset: selection.start - 1,
      );
    }
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
    _isShiftActive.value = !_isShiftActive.value;
  }

  /// Caps cycles: off → uppercase + digit row on dual keys → uppercase + symbol
  /// row on dual keys → off. Shift has no second level.
  void toggleCapsLock() {
    if (!_isCapsLock.value) {
      _isCapsLock.value = true;
      _capsExtended.value = false;
    } else if (!_capsExtended.value) {
      _capsExtended.value = true;
    } else {
      _isCapsLock.value = false;
      _capsExtended.value = false;
    }
    _isShiftActive.value = false;
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

  void _validate() {
    if (validator != null) {
      _validationError.value = validator!(textController.text);
    }
  }

  void _onTextChanged() => _validate();

  List<List<String>> get currentLayout {
    return (_isShiftActive.value || _isCapsLock.value)
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
