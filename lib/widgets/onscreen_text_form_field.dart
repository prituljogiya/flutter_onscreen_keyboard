import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onscreen_keyboard_form_field_scope.dart';

/// [TextFormField] integrated with the on-screen keyboard plugin.
///
/// Prefer [OnscreenKeyboardFormFieldScope] when you already have your own
/// `CustomTextFormField` and only need keyboard rules + wiring.
///
/// App setup (GetX / Material):
///
/// ```dart
/// void main() {
///   FlutterOnscreenKeyboard.configure(
///     OnscreenKeyboardConfig.withColors(colors: myColors, useCustomKeyboard: true),
///   );
///   runApp(
///     OnscreenKeyboardBinding(
///       child: GetMaterialApp(
///         builder: (context, child) => OnscreenKeyboardAttachment(
///           commitOnEnterOnly: true,
///           lockContentWhileKeyboardVisible: true,
///           child: child ?? const SizedBox.shrink(),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
///
/// Do not wrap the whole app in `KeyboardDismissOnTap` — it fights the custom
/// keyboard. Use [OnscreenKeyboardAttachment] flags instead.
class OnscreenTextFormField extends StatelessWidget {
  const OnscreenTextFormField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.decoration,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.allowDecimalInput,
    this.integersOnly,
    this.maxFractionDigits,
    this.validator,
    this.maxLines = 1,
    this.showCursor = true,
    this.enabled = true,
    this.obscureText = false,
    this.inputFormatters,
    this.textInputAction,
    this.initialValue,
    this.style,
    this.textAlign,
    this.cursorColor,
    this.cursorHeight,
    this.autovalidateMode,
    this.onChanged,
    this.onFieldSubmitted,
    this.onSaved,
    this.wrapper,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final bool? allowDecimalInput;
  final bool? integersOnly;
  final int? maxFractionDigits;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool showCursor;
  final bool enabled;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? cursorColor;
  final double? cursorHeight;
  final AutovalidateMode? autovalidateMode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final Widget Function(BuildContext context, Widget field)? wrapper;

  @override
  Widget build(BuildContext context) {
    return OnscreenKeyboardFormFieldScope(
      controller: controller,
      focusNode: focusNode,
      initialValue: initialValue,
      keyboardType: keyboardType,
      minLength: minLength,
      maxLength: maxLength,
      minValue: minValue,
      maxValue: maxValue,
      allowDecimalInput: allowDecimalInput,
      integersOnly: integersOnly,
      maxFractionDigits: maxFractionDigits,
      validator: validator,
      builder: (context, handle) {
        final field = TextFormField(
          key: fieldKey,
          controller: handle.controller,
          focusNode: handle.focusNode,
          keyboardType: keyboardType,
          decoration: decoration,
          maxLines: maxLines,
          maxLength: maxLength,
          showCursor: showCursor,
          readOnly: handle.readOnly,
          enabled: enabled,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          style: style,
          textAlign: textAlign ?? TextAlign.start,
          cursorColor: cursorColor,
          cursorHeight: cursorHeight,
          autovalidateMode: autovalidateMode,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onSaved: onSaved,
        );
        final wrap = wrapper;
        return wrap == null ? field : wrap(context, field);
      },
    );
  }
}
