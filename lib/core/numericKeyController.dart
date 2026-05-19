import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'text_editing_controller_guard.dart';

class NumericKeyboardController extends GetxController {
  TextEditingController textController;
  final FocusNode focusNode;
  String? Function(String)? validator;

  final RxnString _validationError = RxnString();
  bool _active = true;
  bool _hasUserEdited = false;

  String? get validationError => _validationError.value;

  RxnString get validationErrorRx => _validationError;

  String get text => textController.text;
  bool get isActive => _active;

  NumericKeyboardController({
    required this.textController,
    required this.focusNode,
    this.validator,
  });

  void rebind({
    required TextEditingController textController,
    String? Function(String)? validator,
  }) {
    this.textController = textController;
    this.validator = validator;
    _active = true;
    clearValidation();
  }

  @override
  void onClose() {
    _active = false;
    super.onClose();
  }

  bool get _canEdit =>
      _active && isTextEditingControllerUsable(textController);

  void insertDigit(String digit) {
    if (!_canEdit) return;
    _hasUserEdited = true;

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
    _hasUserEdited = true;

    final currentText = textController.text;

    if (!currentText.contains('.')) {
      textController.text = currentText + '.';
    }

    _validate();
  }

  void backspace() {
    if (!_canEdit) return;
    _hasUserEdited = true;

    final currentText = textController.text;

    if (currentText.length > 1) {
      textController.text = currentText.substring(0, currentText.length - 1);
    } else {
      textController.text = '0';
    }

    _validate();
  }

  bool enter() {
    if (!_canEdit) return false;
    _validate(force: true);
    final message = _validationError.value?.trim();
    if (message != null && message.isNotEmpty) {
      return false;
    }
    focusNode.unfocus();
    return true;
  }

  bool closeKeyboard() {
    focusNode.unfocus();
    return true;
  }

  void clear() {
    if (!_canEdit) return;
    textController.text = '0';
    clearValidation();
  }

  void cancel() {
    if (!_canEdit) return;
    textController.text = '0';
    clearValidation();
  }

  void clearValidation() {
    _validationError.value = null;
    _hasUserEdited = false;
  }

  void _validate({bool force = false}) {
    if (!_canEdit) return;
    if (!force && !_hasUserEdited) {
      return;
    }
    final message = validator?.call(textController.text);
    final trimmed = message?.trim();
    _validationError.value =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  void validateNow() => _validate();
}
