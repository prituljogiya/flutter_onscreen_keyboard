import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_mapping.dart';

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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? Function(String)? validator;

  bool get useNumericKeyboard => preferOnscreenNumericKeyboard(keyboardType);
}
