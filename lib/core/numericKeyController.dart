import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'text_editing_controller_guard.dart';

class NumericKeyboardController extends GetxController {
  TextEditingController textController;
  final FocusNode focusNode;
  String? Function(String)? validator;

  final RxnString _validationError = RxnString();
  bool _active = true;

  String? get validationError => _validationError.value;
  String get text => textController.text;
  bool get isActive => _active;

  NumericKeyboardController({
    required this.textController,
    required this.focusNode,
    this.validator,
  }) {
    textController.addListener(_onTextChanged);
  }

  /// Called when [NumericKeyboard] is rebuilt with a new staging controller.
  void rebind({
    required TextEditingController textController,
    String? Function(String)? validator,
  }) {
    if (!identical(this.textController, textController)) {
      if (isTextEditingControllerUsable(this.textController)) {
        this.textController.removeListener(_onTextChanged);
      }
      this.textController = textController;
      textController.addListener(_onTextChanged);
    }
    this.validator = validator;
    _active = true;
  }

  @override
  void onClose() {
    _active = false;
    if (isTextEditingControllerUsable(textController)) {
      textController.removeListener(_onTextChanged);
    }
    super.onClose();
  }

  bool get _canEdit =>
      _active && isTextEditingControllerUsable(textController);

  void insertDigit(String digit) {
    if (!_canEdit) return;

    final currentText = textController.text;

    if (currentText == '0' && digit != '.') {
      textController.text = digit;
    } else {
      textController.text = currentText + digit;
    }

    _validate();
  }

  void insertDecimal() {
    if (!_canEdit) return;

    final currentText = textController.text;

    if (!currentText.contains('.')) {
      textController.text = currentText + '.';
    }

    _validate();
  }

  void backspace() {
    if (!_canEdit) return;

    final currentText = textController.text;

    if (currentText.length > 1) {
      textController.text = currentText.substring(0, currentText.length - 1);
    } else {
      textController.text = '0';
    }

    _validate();
  }

  /// Returns true when value is valid; caller should commit / close UI.
  bool enter() {
    if (!_canEdit) return false;
    _validate();
    if (_validationError.value != null) {
      return false;
    }
    focusNode.unfocus();
    return true;
  }

  /// Dismisses the keyboard only: unfocuses the field. Does not clear text or
  /// validation.
  bool closeKeyboard() {
    focusNode.unfocus();
    return true;
  }

  void clear() {
    if (!_canEdit) return;
    textController.text = '0';
    _validationError.value = null;
  }

  void cancel() {
    if (!_canEdit) return;
    textController.text = '0';
    _validationError.value = null;
  }

  void _validate() {
    if (!_canEdit) return;
    if (validator != null) {
      _validationError.value = validator!(textController.text);
    }
  }

  void _onTextChanged() => _validate();

  /// Call when external rules (e.g. min/max) change without new text input.
  void validateNow() => _validate();
}
