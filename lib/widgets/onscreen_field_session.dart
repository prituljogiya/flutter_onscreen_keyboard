import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_mapping.dart' as keyboard_mapping;

/// Active field metadata passed from [OnscreenTextField] to [OnscreenKeyboardHost].
class OnscreenFieldSession {
  const OnscreenFieldSession({
    required this.controller,
    required this.focusNode,
    required this.keyboardType,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.validator,
    this.allowDecimalInput,
    this.integersOnly,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? Function(String)? validator;

  /// When set, overrides whether the numeric pad shows a `.` key (default true).
  final bool? allowDecimalInput;

  /// When set, overrides whole-number validation (default from [keyboardType]).
  final bool? integersOnly;

  bool get useNumericKeyboard =>
      keyboard_mapping.preferOnscreenNumericKeyboard(keyboardType);

  /// Show `.` on the numeric pad (default true for all numeric fields).
  bool get showDecimalKey => allowDecimalInput ?? true;

  bool get integersOnlyValidation =>
      integersOnly ??
      keyboard_mapping.integersOnlyKeyboardType(keyboardType);
}
