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
        context.getInheritedWidgetOfExactType<OnscreenKeyboardScope>();
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
        context.getInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    return scope?.isOpenFor(focusNode) ?? false;
  }

  /// True while a field session is active (keyboard visible).
  static bool isOpen(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<OnscreenKeyboardScope>();
    return scope?.hasOpenKeyboard ?? false;
  }

  /// Hides the keyboard panel (used by preview close buttons).
  static void dismiss(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<OnscreenKeyboardScope>();
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

/// Notifies [OnscreenTextField] when the active keyboard session changes.
class OnscreenKeyboardScope extends InheritedWidget {
  const OnscreenKeyboardScope({
    required this.state,
    required this.session,
    required super.child,
  });

  final _OnscreenKeyboardHostState state;
  final OnscreenFieldSession? session;

  bool get hasOpenKeyboard => session != null;

  bool isOpenFor(FocusNode focusNode) => session?.focusNode == focusNode;

  @override
  bool updateShouldNotify(OnscreenKeyboardScope oldWidget) {
    return oldWidget.session?.focusNode != session?.focusNode ||
        (oldWidget.session == null) != (session == null);
  }
}

class _OnscreenKeyboardHostState extends State<OnscreenKeyboardHost> {
  OnscreenFieldSession? _session;
  final GlobalKey _alphaKeyboardKey = GlobalKey(debugLabel: 'alphaKeyboard');

  /// Form scroll offset captured when the keyboard opens (restored on close).
  double? _hostScrollOffsetBeforeKeyboard;

  bool isOpenFor(FocusNode focusNode) => _session?.focusNode == focusNode;

  void _captureHostScroll(OnscreenFieldSession session) {
    final ctx = session.focusNode.context;
    if (ctx == null) return;
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return;
    _hostScrollOffsetBeforeKeyboard = scrollable.position.pixels;
  }

  void _restoreHostScrollAfterDismiss(FocusNode fieldFocus, double? offset) {
    _hostScrollOffsetBeforeKeyboard = null;
    if (offset == null) return;

    void apply() {
      if (!mounted) return;
      final ctx = fieldFocus.context;
      if (ctx == null) return;
      final scrollable = Scrollable.maybeOf(ctx);
      if (scrollable == null || !scrollable.position.hasContentDimensions) {
        return;
      }
      final target = offset.clamp(0.0, scrollable.position.maxScrollExtent);
      if ((scrollable.position.pixels - target).abs() > 0.5) {
        scrollable.position.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    });
  }

  void _activate(OnscreenFieldSession session) {
    if (!useCustomOnscreenKeyboard) {
      session.focusNode.requestFocus();
      return;
    }

    // While the keyboard is open, stay on the active field until it is closed.
    if (_session != null &&
        _session!.focusNode.hashCode != session.focusNode.hashCode) {
      return;
    }

    final previous = _session;
    session.focusNode.requestFocus();

    if (_session == null) {
      _captureHostScroll(session);
    }

    if (!identical(previous, session)) {
      setState(() => _session = session);
    }

    clearOnscreenKeyboardValidation(session.focusNode);
  }

  void _dismiss() {
    if (!mounted || _session == null) return;

    final previous = _session!;
    final scrollOffset = _hostScrollOffsetBeforeKeyboard;
    final fieldFocus = previous.focusNode;
    setState(() => _session = null);

    clearOnscreenKeyboardValidation(previous.focusNode);
    previous.focusNode.unfocus();

    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus();
    }

    _restoreHostScrollAfterDismiss(fieldFocus, scrollOffset);

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

    return PopScope(
      canPop: session == null,
      child: OnscreenKeyboardScope(
        state: this,
        session: session,
        child: useDraggable
            ? _buildDraggableShell(session)
            : _buildPortraitShell(session),
      ),
    );
  }

  Widget _wrapLockedContent(Widget child) {
    if (_session == null) return child;
    return ScrollConfiguration(
      behavior: const _LockScrollWhileKeyboardBehavior(),
      child: child,
    );
  }

  Widget _buildDraggableShell(OnscreenFieldSession? session) {
    if (session == null) {
      return widget.child;
    }

    return DraggableDynamicKeyboard(
      key: ValueKey<String>('drag_kb_${session.focusNode.hashCode}'),
      controller: session.controller,
      focusNode: session.focusNode,
      commitOnEnterOnly: widget.commitOnEnterOnly,
      useNumericKeyboard: session.useNumericKeyboard,
      numericMinValue: session.minValue,
      numericMaxValue: session.maxValue,
      numericAllowDecimalInput: session.showDecimalKey,
      numericIntegersOnly: session.integersOnlyValidation,
      minLength: session.useNumericKeyboard ? null : session.minLength,
      maxLength: session.maxLength,
      validator: session.validator,
      widthFactor: widget.draggableWidthFactor,
      heightFactor: widget.draggableHeightFactor,
      fullWidthInLandscape: false,
      alwaysVisible: true,
      pushContent: false,
      onDismiss: _dismiss,
      onEnterPressed: _onEnter,
      child: _wrapLockedContent(widget.child),
    );
  }

  Widget _buildPortraitShell(OnscreenFieldSession? session) {
    return TapRegion(
      onTapOutside: (_) => _dismiss(),
      child: Column(
        children: [
          Expanded(child: _wrapLockedContent(widget.child)),
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
            'nk_${session.focusNode.hashCode}_${session.showDecimalKey}_${session.integersOnlyValidation}_${session.maxLength}',
          ),
          controller: session.controller,
          focusNode: session.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minValue: session.minValue,
          maxValue: session.maxValue,
          allowDecimalInput: session.showDecimalKey,
          integersOnly: session.integersOnlyValidation,
          maxLength: session.maxLength,
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

/// Disables form scrolling while the on-screen keyboard is open.
class _LockScrollWhileKeyboardBehavior extends ScrollBehavior {
  const _LockScrollWhileKeyboardBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const NeverScrollableScrollPhysics();
  }
}
