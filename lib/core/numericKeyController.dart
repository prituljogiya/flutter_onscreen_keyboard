import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'numeric_range.dart';
import 'text_editing_controller_guard.dart';

class NumericKeyboardController extends GetxController {
  TextEditingController textController;
  final FocusNode focusNode;
  /// Preview strip focus (caret). May be set after [Get.find] if created without it.
  FocusNode? previewFocusNode;
  String? Function(String)? validator;
  bool allowDecimalInput;

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
    this.previewFocusNode,
    this.validator,
    this.allowDecimalInput = true,
  });

  void rebind({
    required TextEditingController textController,
    FocusNode? previewFocusNode,
    String? Function(String)? validator,
    bool? allowDecimalInput,
  }) {
    this.textController = textController;
    if (previewFocusNode != null) {
      this.previewFocusNode = previewFocusNode;
    }
    this.validator = validator;
    if (allowDecimalInput != null) {
      this.allowDecimalInput = allowDecimalInput;
    }
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

  void _applyEditingValue(String text, int caretOffset) {
    if (!_canEdit) return;
    final offset = caretOffset.clamp(0, text.length);
    textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  void insertDigit(String digit) {
    if (!_canEdit) return;
    _hasUserEdited = true;

    final currentText = textController.text;
    final String newText;
    if (currentText == '0' && digit != '.') {
      newText = digit;
    } else {
      newText = currentText + digit;
    }

    _applyEditingValue(newText, newText.length);
    _validate();
  }

  void insertDecimal() {
    if (!_canEdit || !allowDecimalInput) return;
    _hasUserEdited = true;

    final currentText = textController.text;
    if (currentText.contains('.')) return;

    final newText = '$currentText.';
    _applyEditingValue(newText, newText.length);
    _validate();
  }

  void backspace() {
    if (!_canEdit) return;
    _hasUserEdited = true;

    final currentText = textController.text;
    final String newText;
    if (currentText.length > 1) {
      newText = currentText.substring(0, currentText.length - 1);
    } else {
      newText = '0';
    }

    _applyEditingValue(newText, newText.length);
    _validate();
  }

  void applyValidationError(String? message) {
    final trimmed = message?.trim();
    _validationError.value =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  bool enter({String? Function(String value)? strictValidator}) {
    if (!_canEdit) return false;
    if (strictValidator != null) {
      applyValidationError(strictValidator(textController.text));
    } else {
      _validate(force: true);
    }
    final message = _validationError.value?.trim();
    if (message != null && message.isNotEmpty) {
      return false;
    }
    previewFocusNode?.unfocus();
    focusNode.unfocus();
    return true;
  }

  bool closeKeyboard() {
    previewFocusNode?.unfocus();
    focusNode.unfocus();
    return true;
  }

  void clear() {
    if (!_canEdit) return;
    _applyEditingValue('0', 1);
    clearValidation();
  }

  void cancel() {
    if (!_canEdit) return;
    _applyEditingValue('0', 1);
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
    if (!force && NumericRange.isIncompleteDecimal(textController.text)) {
      _validationError.value = null;
      return;
    }
    final message = validator?.call(textController.text);
    final trimmed = message?.trim();
    _validationError.value =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  void validateNow() => _validate();
}
