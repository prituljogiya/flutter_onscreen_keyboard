import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
import 'onscreen_field_session.dart';
import 'onscreen_keyboard_field_rules.dart';
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
    this.maxFractionDigits,
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

  /// Hard cap on digits after `.` on the numeric pad. When null, the cap is
  /// inferred from [minValue] / [maxValue] (if set), otherwise no cap. Set
  /// this on decimal fields without bounds to stop the user typing
  /// arbitrarily long fractional parts (e.g. `0.123456789`).
  final int? maxFractionDigits;
  final String? Function(String)? validator;
  final int? maxLines;
  final bool showCursor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OnscreenTextField> createState() => _OnscreenTextFieldState();
}

class _OnscreenTextFieldState extends State<OnscreenTextField> {
  String? _keyboardValidator(String value) => widget.validator?.call(value);

  OnscreenFieldRule get _rule => OnscreenFieldRule(
        minLength: widget.minLength,
        maxLength: widget.maxLength,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        maxFractionDigits: widget.maxFractionDigits,
        validator: _keyboardValidator,
      );

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
        maxFractionDigits: widget.maxFractionDigits,
        validator: _keyboardValidator,
      );

  @override
  void initState() {
    super.initState();
    _registerRules();
  }

  @override
  void didUpdateWidget(covariant OnscreenTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minLength != widget.minLength ||
        oldWidget.maxLength != widget.maxLength ||
        oldWidget.minValue != widget.minValue ||
        oldWidget.maxValue != widget.maxValue ||
        oldWidget.validator != widget.validator) {
      _registerRules();
    }
  }

  @override
  void dispose() {
    OnscreenKeyboardFieldRules.unregister(widget.focusNode);
    super.dispose();
  }

  void _registerRules() {
    if (!useCustomOnscreenKeyboard) return;
    OnscreenKeyboardFieldRules.register(widget.focusNode, _rule);
  }

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
    if (scope == null) {
      // Compatibility mode: when used without [OnscreenKeyboardHost] (for
      // example with root-level [OnscreenKeyboardAttachment]), behave like a
      // regular TextField so the global TextInput bridge can drive the custom
      // keyboard for this field.
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

    final blocked = scope.hasOpenKeyboard && !scope.isOpenFor(widget.focusNode);

    // The field is rendered as a regular [TextField] but we intentionally
    // prevent it from receiving pointer events directly. Flutter's
    // [TextField] (via its internal gesture recognizer) focuses itself on
    // tap, and once focused, [EditableText] schedules a "scroll caret into
    // view" animation on the enclosing [Scrollable] — that's the source of
    // the "blink" / form jump when the on-screen keyboard opens. We absorb
    // the pointer at the field and route the tap through our own
    // [GestureDetector] so the field never gets focus.
    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      readOnly: true,
      showCursor: widget.showCursor && !blocked,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      decoration: widget.decoration,
    );

    final absorbed = AbsorbPointer(child: field);

    if (blocked) {
      return absorbed;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (OnscreenKeyboardHost.isOpenFor(context, widget.focusNode)) {
          return;
        }
        OnscreenKeyboardHost.activate(context, _session);
      },
      child: absorbed,
    );
  }
}
