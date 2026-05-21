import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
import 'onscreen_field_session.dart';
import 'onscreen_keyboard_host.dart';

/// Text field that uses the on-screen custom keyboard when
/// [OnscreenKeyboardConfig.useCustomKeyboard] is true; otherwise behaves like a
/// normal [TextField] with the system keyboard.
class OnscreenTextField extends StatefulWidget {
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
    this.allowDecimalInput,
    this.integersOnly,
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
  final num? minValue;
  final num? maxValue;

  /// When set, controls whether the numeric pad shows a `.` key (default true).
  final bool? allowDecimalInput;

  /// When set, values must be whole numbers; range min/max still applies.
  final bool? integersOnly;
  final String? Function(String)? validator;
  final int? maxLines;
  final bool showCursor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OnscreenTextField> createState() => _OnscreenTextFieldState();
}

class _OnscreenTextFieldState extends State<OnscreenTextField> {
  OnscreenFieldSession get _session => OnscreenFieldSession(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        minLength: widget.minLength,
        maxLength: widget.maxLength,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        validator: widget.validator,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!useCustomOnscreenKeyboard) return;
    _syncFocusPolicy(context);
  }

  void _syncFocusPolicy(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    final blocked = scope != null &&
        scope.hasOpenKeyboard &&
        !scope.isOpenFor(widget.focusNode);

    widget.focusNode.canRequestFocus = !blocked;
    if (blocked && widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!useCustomOnscreenKeyboard) {
      return TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        decoration: widget.decoration,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      );
    }

    final scope =
        context.dependOnInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    final blocked = scope != null &&
        scope.hasOpenKeyboard &&
        !scope.isOpenFor(widget.focusNode);

    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      readOnly: true,
      showCursor: widget.showCursor && !blocked,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onTap: blocked
          ? null
          : () {
              if (OnscreenKeyboardHost.isOpenFor(context, widget.focusNode)) {
                return;
              }
              OnscreenKeyboardHost.activate(context, _session);
            },
      decoration: widget.decoration,
    );

    if (!blocked) return field;

    return AbsorbPointer(child: field);
  }
}
