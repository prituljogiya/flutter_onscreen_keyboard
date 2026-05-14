import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeyboardController extends GetxController {
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback? onEnterPressed;
  final String? Function(String)? validator;

  int? maxLength;

  final RxBool _isShiftActive = false.obs;
  final RxBool _isCapsLock = false.obs;
  final RxBool _isNumericMode = false.obs;
  final RxBool _isSymbolsMode = false.obs;
  final RxBool _isEmojiMode = false.obs;
  final RxnString _validationError = RxnString();

  bool get isShiftActive => _isShiftActive.value;
  bool get isCapsLock => _isCapsLock.value;
  bool get isNumericMode => _isNumericMode.value;
  bool get isSymbolsMode => _isSymbolsMode.value;
  bool get isEmojiMode => _isEmojiMode.value;
  String? get validationError => _validationError.value;
  String get text => textController.text;

  KeyboardController({
    required this.textController,
    required this.focusNode,
    this.onEnterPressed,
    this.validator,
    this.maxLength,
  }) {
    textController.addListener(_onTextChanged);
  }

  @override
  void onClose() {
    textController.removeListener(_onTextChanged);
    super.onClose();
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

    if (_isShiftActive.value && !_isCapsLock.value) {
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
    focusNode.unfocus();
    return true;
  }

  bool closeKeyboard() {
    textController.clear();

    textController.selection = const TextSelection.collapsed(offset: 0);

    _validationError.value = null;

    focusNode.unfocus();

    return true;
  }

  void insertSpace() => insertText(' ');

  void toggleShift() {
    _isShiftActive.value = !_isShiftActive.value;
  }

  void toggleCapsLock() {
    _isCapsLock.value = !_isCapsLock.value;
    if (_isCapsLock.value) {
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
