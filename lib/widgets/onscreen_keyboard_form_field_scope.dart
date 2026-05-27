import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
import 'onscreen_field_session.dart';
import 'onscreen_keyboard_field_rules.dart';
import 'onscreen_keyboard_host.dart';

/// Handle passed to [OnscreenKeyboardFormFieldScope.builder] for wiring your own
/// [TextFormField] (e.g. `CustomTextFormField`).
class OnscreenKeyboardFormFieldHandle {
  const OnscreenKeyboardFormFieldHandle({
    required this.controller,
    required this.focusNode,
    required this.readOnly,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// When true, set on [TextFormField.readOnly] (host mode only).
  final bool readOnly;
}

/// Registers on-screen keyboard rules and host/attachment behavior around any
/// [TextFormField] you build in [builder].
///
/// Use this when you already have a styled wrapper (`CustomTextFormField`) and
/// only need keyboard integration + [OnscreenTextField] validation params.
class OnscreenKeyboardFormFieldScope extends StatefulWidget {
  const OnscreenKeyboardFormFieldScope({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.allowDecimalInput,
    this.integersOnly,
    this.maxFractionDigits,
    this.validator,
    required this.builder,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final TextInputType keyboardType;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final bool? allowDecimalInput;
  final bool? integersOnly;
  final int? maxFractionDigits;

  /// Used for keyboard live validation and optional [Form] validation.
  final String? Function(String?)? validator;

  final Widget Function(
    BuildContext context,
    OnscreenKeyboardFormFieldHandle handle,
  ) builder;

  @override
  State<OnscreenKeyboardFormFieldScope> createState() =>
      _OnscreenKeyboardFormFieldScopeState();
}

class _OnscreenKeyboardFormFieldScopeState
    extends State<OnscreenKeyboardFormFieldScope> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _usingHost =>
      useCustomOnscreenKeyboard &&
      context.findAncestorWidgetOfExactType<OnscreenKeyboardHost>() != null;

  String? _keyboardValidator(String value) =>
      widget.validator?.call(value);

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
        controller: _controller,
        focusNode: _focusNode,
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

  OnscreenKeyboardFormFieldHandle get _handle => OnscreenKeyboardFormFieldHandle(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: useCustomOnscreenKeyboard && _usingHost,
      );

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    final initial = widget.initialValue;
    if (initial != null && _controller.text.isEmpty) {
      _controller.text = initial;
    }
    _registerRules();
  }

  @override
  void didUpdateWidget(covariant OnscreenKeyboardFormFieldScope oldWidget) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!useCustomOnscreenKeyboard) return;
    _syncFocusPolicy(context);
  }

  @override
  void dispose() {
    OnscreenKeyboardFieldRules.unregister(_focusNode);
    _ownedFocusNode?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _registerRules() {
    if (!useCustomOnscreenKeyboard) return;
    OnscreenKeyboardFieldRules.register(_focusNode, _rule);
  }

  void _syncFocusPolicy(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    final blocked = scope != null &&
        scope.hasOpenKeyboard &&
        !scope.isOpenFor(_focusNode);

    _focusNode.canRequestFocus = !blocked;
    if (blocked && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.builder(context, _handle);

    if (!useCustomOnscreenKeyboard || !_usingHost) {
      return field;
    }

    final scope =
        context.dependOnInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    final blocked =
        scope != null && scope.hasOpenKeyboard && !scope.isOpenFor(_focusNode);

    final absorbed = AbsorbPointer(child: field);

    if (blocked) {
      return absorbed;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (OnscreenKeyboardHost.isOpenFor(context, _focusNode)) {
          return;
        }
        OnscreenKeyboardHost.activate(context, _session);
      },
      child: absorbed,
    );
  }
}
