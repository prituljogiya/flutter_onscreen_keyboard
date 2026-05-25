import 'package:flutter/material.dart';

import 'numeric_range.dart';
import 'text_editing_controller_guard.dart';

/// Drives the on-screen numeric keyboard.
///
/// Plain Dart state, published via [ChangeNotifier]; listen with
/// [ListenableBuilder] (no GetX required).
class NumericKeyboardController extends ChangeNotifier {
  TextEditingController textController;
  final FocusNode focusNode;

  /// Preview strip focus (caret). Optional, can be assigned after construction.
  FocusNode? previewFocusNode;
  String? Function(String)? validator;
  bool allowDecimalInput;
  bool integersOnly;
  num? minValue;
  num? maxValue;
  int? maxLength;

  String? _validationError;
  bool _active = true;
  bool _hasUserEdited = false;

  String? get validationError => _validationError;

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
  void dispose() {
    _active = false;
    super.dispose();
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
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (_validationError == next) return;
    _validationError = next;
    notifyListeners();
  }

  bool enter({String? Function(String value)? strictValidator}) {
    if (!_canEdit) return false;
    if (strictValidator != null) {
      applyValidationError(strictValidator(textController.text));
    } else {
      _validate(force: true);
    }
    final message = _validationError?.trim();
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
    final hadError = _validationError != null;
    _validationError = null;
    _hasUserEdited = false;
    if (hadError) notifyListeners();
  }

  void _validate({bool force = false}) {
    if (!_canEdit) return;
    if (!force && !_hasUserEdited) {
      return;
    }
    if (!force && NumericRange.isIncompleteDecimal(textController.text)) {
      if (_validationError != null) {
        _validationError = null;
        notifyListeners();
      }
      return;
    }
    final message = validator?.call(textController.text);
    final trimmed = message?.trim();
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (_validationError == next) return;
    _validationError = next;
    notifyListeners();
  }

  void validateNow() => _validate(force: true);
}
