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
  bool integersOnly;
  num? minValue;
  num? maxValue;
  int? maxLength;

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
    this.integersOnly = false,
    this.minValue,
    this.maxValue,
    this.maxLength,
  });

  bool get canInsertDecimal => allowDecimalInput && !integersOnly;

  void rebind({
    required TextEditingController textController,
    FocusNode? previewFocusNode,
    String? Function(String)? validator,
    bool? allowDecimalInput,
    bool? integersOnly,
    num? minValue,
    num? maxValue,
    int? maxLength,
  }) {
    this.textController = textController;
    if (previewFocusNode != null) {
      this.previewFocusNode = previewFocusNode;
    }
    this.validator = validator;
    if (allowDecimalInput != null) {
      this.allowDecimalInput = allowDecimalInput;
    }
    if (integersOnly != null) {
      this.integersOnly = integersOnly;
    }
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.maxLength = maxLength;
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

    final currentText = textController.text;
    if (!NumericRange.canAcceptDigit(
      currentText: currentText,
      digit: digit,
      min: minValue,
      max: maxValue,
      integersOnly: integersOnly,
      maxLength: maxLength,
    )) {
      return;
    }

    _hasUserEdited = true;

    final String newText;
    if ((currentText.isEmpty || currentText == '0') && digit != '.') {
      newText = digit;
    } else {
      newText = currentText + digit;
    }

    _applyEditingValue(newText, newText.length);
    _validate();
  }

  /// Returns false when `.` is not allowed (no text change).
  bool insertDecimal() {
    if (!_canEdit || !canInsertDecimal) return false;
    _hasUserEdited = true;

    final currentText = textController.text;
    if (currentText.contains('.')) return false;

    final newText = currentText.isEmpty ? '0.' : '$currentText.';
    _applyEditingValue(newText, newText.length);
    _validate();
    return true;
  }

  void backspace() {
    if (!_canEdit) return;
    _hasUserEdited = true;

    final currentText = textController.text;
    if (currentText.isEmpty) return;

    final String newText;
    if (currentText.length > 1) {
      newText = currentText.substring(0, currentText.length - 1);
    } else {
      newText = '';
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
    _hasUserEdited = false;
    _applyEditingValue('', 0);
    clearValidation();
  }

  void cancel() {
    if (!_canEdit) return;
    _hasUserEdited = false;
    _applyEditingValue('', 0);
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

  void validateNow() => _validate(force: true);
}
