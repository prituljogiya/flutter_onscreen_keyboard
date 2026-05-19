import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
import '../core/onscreen_keyboard_validation.dart';
import 'custom_keyboard.dart';
import 'draggable.dart';
import 'numeric.dart';
import 'onscreen_field_session.dart';

/// Wraps a screen (or form) and shows [CustomKeyboard] / [NumericKeyboard] when
/// an [OnscreenTextField] is focused — only if [useCustomOnscreenKeyboard] is true.
///
/// When the flag is false, [child] is returned unchanged (system keyboard only).
class OnscreenKeyboardHost extends StatefulWidget {
  const OnscreenKeyboardHost({
    super.key,
    required this.child,
    this.commitOnEnterOnly = true,
    this.onEnterPressed,
    this.onTapOutside,
    this.useDraggableInLandscape = true,
    this.draggableWidthFactor = 0.5,
    this.draggableHeightFactor = 0.5,
  });

  final Widget child;
  final bool commitOnEnterOnly;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onTapOutside;
  final bool useDraggableInLandscape;
  final double draggableWidthFactor;
  final double draggableHeightFactor;

  /// Opens the on-screen keyboard for [session] (used by [OnscreenTextField]).
  static void activate(BuildContext context, OnscreenFieldSession session) {
    final state = context
        .findAncestorStateOfType<_OnscreenKeyboardHostState>();
    state?._activate(session);
  }

  @override
  State<OnscreenKeyboardHost> createState() => _OnscreenKeyboardHostState();
}

class _OnscreenKeyboardHostState extends State<OnscreenKeyboardHost> {
  OnscreenFieldSession? _session;

  void _activate(OnscreenFieldSession session) {
    if (!useCustomOnscreenKeyboard) {
      session.focusNode.requestFocus();
      return;
    }
    final previous = _session;
    if (previous != null &&
        previous.focusNode.hashCode != session.focusNode.hashCode) {
      clearOnscreenKeyboardValidation(previous.focusNode);
    }
    setState(() => _session = session);
    clearOnscreenKeyboardValidation(session.focusNode);
    session.focusNode.requestFocus();
  }

  void _dismiss() {
    if (!mounted) return;
    final previous = _session;
    if (previous != null) {
      clearOnscreenKeyboardValidation(previous.focusNode);
    }
    setState(() => _session = null);
    widget.onTapOutside?.call();
  }

  void _onEnter() {
    widget.onEnterPressed?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!useCustomOnscreenKeyboard) {
      return widget.child;
    }

    final session = _session;
    if (session == null) {
      return widget.child;
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final useNumeric = session.useNumericKeyboard;

    if (isLandscape && widget.useDraggableInLandscape) {
      return DraggableDynamicKeyboard(
        controller: session.controller,
        focusNode: session.focusNode,
        commitOnEnterOnly: widget.commitOnEnterOnly,
        useNumericKeyboard: useNumeric,
        numericMinValue: session.minValue,
        numericMaxValue: session.maxValue,
        minLength: useNumeric ? null : session.minLength,
        maxLength: useNumeric ? null : session.maxLength,
        validator: session.validator,
        widthFactor: widget.draggableWidthFactor,
        heightFactor: widget.draggableHeightFactor,
        fullWidthInLandscape: false,
        alwaysVisible: true,
        pushContent: false,
        onTapOutside: _dismiss,
        onEnterPressed: _onEnter,
        child: widget.child,
      );
    }

    return TapRegion(
      onTapOutside: (_) {
        session.focusNode.unfocus();
        _dismiss();
      },
      child: Column(
        children: [
          Expanded(child: widget.child),
          if (useNumeric)
            NumericKeyboard(
              key: ValueKey<int>(session.focusNode.hashCode),
              controller: session.controller,
              focusNode: session.focusNode,
              commitOnEnterOnly: widget.commitOnEnterOnly,
              minValue: session.minValue,
              maxValue: session.maxValue,
              validator: session.validator,
              onTapOutside: _dismiss,
              onEnterPressed: _onEnter,
            )
          else
            CustomKeyboard(
              controller: session.controller,
              focusNode: session.focusNode,
              commitOnEnterOnly: widget.commitOnEnterOnly,
              minLength: session.minLength,
              maxLength: session.maxLength,
              validator: session.validator,
              onTapOutside: _dismiss,
              onEnterPressed: _onEnter,
            ),
        ],
      ),
    );
  }
}
