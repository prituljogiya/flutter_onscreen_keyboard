import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_config.dart';
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

  /// Stable identity anchor for [widget.child] so its element (and any
  /// [Scrollable] state inside it, including the user's current scroll
  /// offset) is preserved when the keyboard mounts/unmounts and the form
  /// moves to a new parent slot.
  final GlobalKey _formAnchorKey =
      GlobalKey(debugLabel: 'onscreenFormAnchor');

  /// Form scroll offset captured when the keyboard opens (restored on close).
  double? _hostScrollOffsetBeforeKeyboard;

  Widget get _anchoredChild =>
      KeyedSubtree(key: _formAnchorKey, child: widget.child);

  bool isOpenFor(FocusNode focusNode) => _session?.focusNode == focusNode;

  double? _capturedScrollOffset(FocusNode focusNode) {
    final ctx = focusNode.context;
    if (ctx == null) return null;
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return null;
    if (!scrollable.position.hasContentDimensions) return null;
    return scrollable.position.pixels;
  }

  /// [TextField] auto-scrolls the enclosing [Scrollable] to show the caret when
  /// it gains focus. Override that animation by jumping back to [offset] on the
  /// next two frames so the form does not visually shift when the keyboard
  /// opens.
  void _pinScrollOffset(FocusNode focusNode, double offset) {
    void apply() {
      if (!mounted) return;
      final ctx = focusNode.context;
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

    final isFirstOpen = _session == null;
    final scrollBefore = _capturedScrollOffset(session.focusNode);

    final previous = _session;

    // Important: we do NOT call `session.focusNode.requestFocus()` here.
    // Focusing the field would make Flutter's [EditableText] call
    // `_showCaretOnScreen()`, which programmatically scrolls the enclosing
    // [Scrollable] to keep the caret in view — that's what was causing the
    // "blink" / scroll jump when the keyboard opened. The keyboard panel owns
    // its own preview text field (with its own focus/caret) and the host
    // field receives committed text on Enter, so it never needs focus.

    if (isFirstOpen) {
      _hostScrollOffsetBeforeKeyboard = scrollBefore;
    }

    if (!identical(previous, session)) {
      setState(() => _session = session);
    }

    // Defensive: even though we no longer focus the field, the previous
    // pin guard still helps if any code path triggers a scroll change while
    // the keyboard is opening.
    if (scrollBefore != null) {
      _pinScrollOffset(session.focusNode, scrollBefore);
    }
  }

  void _dismiss() {
    if (!mounted || _session == null) return;

    final previous = _session!;
    final scrollOffset = _hostScrollOffsetBeforeKeyboard;
    final fieldFocus = previous.focusNode;
    setState(() => _session = null);

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
      return _anchoredChild;
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
      return _anchoredChild;
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
      numericMaxFractionDigits: session.maxFractionDigits,
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
      child: _wrapLockedContent(_anchoredChild),
    );
  }

  Widget _buildPortraitShell(OnscreenFieldSession? session) {
    return TapRegion(
      onTapOutside: (_) => _dismiss(),
      child: Column(
        children: [
          Expanded(child: _wrapLockedContent(_anchoredChild)),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: session != null
                ? _buildActiveKeyboard(session)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveKeyboard(OnscreenFieldSession session) {
    if (session.useNumericKeyboard) {
      return RepaintBoundary(
        child: NumericKeyboard(
          key: ValueKey<String>(
            'nk_${session.focusNode.hashCode}_${session.showDecimalKey}_${session.integersOnlyValidation}_${session.maxLength}_${session.maxFractionDigits}',
          ),
          controller: session.controller,
          focusNode: session.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minValue: session.minValue,
          maxValue: session.maxValue,
          allowDecimalInput: session.showDecimalKey,
          integersOnly: session.integersOnlyValidation,
          maxLength: session.maxLength,
          maxFractionDigits: session.maxFractionDigits,
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
