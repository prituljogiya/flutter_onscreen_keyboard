import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class NumericKeyboardController extends GetxController {
  final TextEditingController textController;
  final FocusNode focusNode;
  final String? Function(String)? validator;

  final RxnString _validationError = RxnString();

  String? get validationError => _validationError.value;
  String get text => textController.text;

  NumericKeyboardController({
    required this.textController,
    required this.focusNode,
    this.validator,
  }) {
    textController.addListener(_onTextChanged);
  }

  @override
  void onClose() {
    textController.removeListener(_onTextChanged);
    super.onClose();
  }

  void insertDigit(String digit) {
    final currentText = textController.text;

    if (currentText == '0' && digit != '.') {
      textController.text = digit;
    } else {
      textController.text = currentText + digit;
    }

    _validate();
  }

  void insertDecimal() {
    final currentText = textController.text;

    if (!currentText.contains('.')) {
      textController.text = currentText + '.';
    }

    _validate();
  }

  void backspace() {
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
    textController.text = '0';
    _validationError.value = null;
  }

  void cancel() {
    textController.text = '0';
    _validationError.value = null;
  }

  void _validate() {
    if (validator != null) {
      _validationError.value = validator!(textController.text);
    }
  }

  void _onTextChanged() => _validate();

  /// Call when external rules (e.g. min/max) change without new text input.
  void validateNow() => _validate();
}
