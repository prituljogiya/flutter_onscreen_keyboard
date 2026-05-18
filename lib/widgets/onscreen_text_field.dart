import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
import 'onscreen_field_session.dart';
import 'onscreen_keyboard_host.dart';

/// Text field that uses the on-screen custom keyboard when
/// [OnscreenKeyboardConfig.useCustomKeyboard] is true; otherwise behaves like a
/// normal [TextField] with the system keyboard.
class OnscreenTextField extends StatelessWidget {
  const OnscreenTextField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    this.keyboardType = TextInputType.text,
    this.decoration,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.validator,
    this.maxLines = 1,
    this.showCursor = true,
    this.onChanged,
    this.onSubmitted,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final int? minLength;
  final int? maxLength;
  final int? minValue;
  final int? maxValue;
  final String? Function(String)? validator;
  final int? maxLines;
  final bool showCursor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  OnscreenFieldSession get _session => OnscreenFieldSession(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        minLength: minLength,
        maxLength: maxLength,
        minValue: minValue,
        maxValue: maxValue,
        validator: validator,
      );

  @override
  Widget build(BuildContext context) {
    if (!useCustomOnscreenKeyboard) {
      return TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        decoration: decoration,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    }

    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      readOnly: true,
      showCursor: showCursor,
      maxLines: maxLines,
      maxLength: maxLength,
      onTap: () => OnscreenKeyboardHost.activate(context, _session),
      decoration: decoration,
    );
  }
}
