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
    final scope =
        context.getInheritedWidgetOfExactType<_OnscreenKeyboardScope>();
    if (scope != null) {
      scope.state._activate(session);
      return;
    }
    context
        .findAncestorStateOfType<_OnscreenKeyboardHostState>()
        ?._activate(session);
  }

  /// Whether the keyboard is open for [focusNode].
  static bool isOpenFor(BuildContext context, FocusNode focusNode) {
    final scope =
        context.getInheritedWidgetOfExactType<_OnscreenKeyboardScope>();
    return scope?.state.isOpenFor(focusNode) ?? false;
  }

  /// Hides the keyboard panel (used by preview close buttons).
  static void dismiss(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_OnscreenKeyboardScope>();
    if (scope != null) {
      scope.state._dismiss();
      return;
    }
    context
        .findAncestorStateOfType<_OnscreenKeyboardHostState>()
        ?._dismiss();
  }

  @override
  State<OnscreenKeyboardHost> createState() => _OnscreenKeyboardHostState();
}

class _OnscreenKeyboardScope extends InheritedWidget {
  const _OnscreenKeyboardScope({
    required this.state,
    required super.child,
  });

  final _OnscreenKeyboardHostState state;

  @override
  bool updateShouldNotify(_OnscreenKeyboardScope oldWidget) => false;
}

class _OnscreenKeyboardHostState extends State<OnscreenKeyboardHost> {
  OnscreenFieldSession? _session;
  final GlobalKey _alphaKeyboardKey = GlobalKey(debugLabel: 'alphaKeyboard');

  bool isOpenFor(FocusNode focusNode) => _session?.focusNode == focusNode;

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

    session.focusNode.requestFocus();

    if (!identical(previous, session)) {
      setState(() => _session = session);
    }

    clearOnscreenKeyboardValidation(session.focusNode);
  }

  void _dismiss() {
    if (!mounted || _session == null) return;

    final previous = _session!;
    setState(() => _session = null);

    clearOnscreenKeyboardValidation(previous.focusNode);
    previous.focusNode.unfocus();

    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus();
    }

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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final useDraggable =
        isLandscape && widget.useDraggableInLandscape;

    return _OnscreenKeyboardScope(
      state: this,
      child: useDraggable
          ? _buildDraggableShell(session)
          : _buildPortraitShell(session),
    );
  }

  Widget _buildDraggableShell(OnscreenFieldSession? session) {
    if (session == null) {
      return widget.child;
    }

    return DraggableDynamicKeyboard(
      controller: session.controller,
      focusNode: session.focusNode,
      commitOnEnterOnly: widget.commitOnEnterOnly,
      useNumericKeyboard: session.useNumericKeyboard,
      numericMinValue: session.minValue,
      numericMaxValue: session.maxValue,
      numericAllowDecimalInput: session.showDecimalKey,
      numericIntegersOnly: session.integersOnlyValidation,
      minLength: session.useNumericKeyboard ? null : session.minLength,
      maxLength: session.useNumericKeyboard ? null : session.maxLength,
      validator: session.validator,
      widthFactor: widget.draggableWidthFactor,
      heightFactor: widget.draggableHeightFactor,
      fullWidthInLandscape: false,
      alwaysVisible: true,
      pushContent: false,
      onDismiss: _dismiss,
      onEnterPressed: _onEnter,
      child: widget.child,
    );
  }

  Widget _buildPortraitShell(OnscreenFieldSession? session) {
    return TapRegion(
      onTapOutside: (_) => _dismiss(),
      child: Column(
        children: [
          Expanded(child: widget.child),
          if (session != null) _buildActiveKeyboard(session),
        ],
      ),
    );
  }

  Widget _buildActiveKeyboard(OnscreenFieldSession session) {
    if (session.useNumericKeyboard) {
      return RepaintBoundary(
        child: NumericKeyboard(
          key: ValueKey<String>(
            'nk_${session.focusNode.hashCode}_${session.showDecimalKey}_${session.integersOnlyValidation}',
          ),
          controller: session.controller,
          focusNode: session.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minValue: session.minValue,
          maxValue: session.maxValue,
          allowDecimalInput: session.showDecimalKey,
          integersOnly: session.integersOnlyValidation,
          validator: session.validator,
          onDismiss: _dismiss,
          onEnterPressed: _onEnter,
        ),
      );
    }

    return RepaintBoundary(
      child: CustomKeyboard(
        key: _alphaKeyboardKey,
        controller: session.controller,
        focusNode: session.focusNode,
        commitOnEnterOnly: widget.commitOnEnterOnly,
        minLength: session.minLength,
        maxLength: session.maxLength,
        validator: session.validator,
        onDismiss: _dismiss,
        onEnterPressed: _onEnter,
      ),
    );
  }
}
