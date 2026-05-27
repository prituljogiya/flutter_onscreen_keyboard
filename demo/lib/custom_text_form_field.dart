import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// Example: keep your app's `CustomTextFormField` API and add keyboard rules.
class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.initialValue,
    this.controller,
    this.enabled = true,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.width = 200,
    this.height = 40,
    this.hintText,
    this.decoration,
    this.obscureText = false,
    this.margin,
    this.textAlign,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.allowDecimalInput,
    this.integersOnly,
    this.maxFractionDigits,
  });

  final String? initialValue;
  final TextEditingController? controller;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final double width;
  final double height;
  final String? hintText;
  final InputDecoration? decoration;
  final bool obscureText;
  final EdgeInsetsGeometry? margin;
  final TextAlign? textAlign;

  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final bool? allowDecimalInput;
  final bool? integersOnly;
  final int? maxFractionDigits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldDecoration = decoration ??
        InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );

    return OnscreenKeyboardFormFieldScope(
      controller: controller,
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
        return Container(
          height: height,
          width: width,
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.08, 0.8],
            ),
          ),
          child: TextFormField(
            textAlign: textAlign ?? TextAlign.start,
            controller: handle.controller,
            focusNode: handle.focusNode,
            readOnly: handle.readOnly,
            enabled: enabled,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            cursorColor: theme.colorScheme.error,
            obscureText: obscureText,
            cursorHeight: 14,
            maxLength: maxLength,
            style: TextStyle(
              fontSize: 14,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            decoration: fieldDecoration,
            onChanged: onChanged,
            validator: validator,
          ),
        );
      },
    );
  }
}
