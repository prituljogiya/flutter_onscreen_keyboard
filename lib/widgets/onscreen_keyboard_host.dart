import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
    /// Builds keyboard panels after the first frame so the first field tap is fast.
    this.prewarmKeyboards = true,
  });

  final Widget child;
  final bool commitOnEnterOnly;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onTapOutside;
  final bool useDraggableInLandscape;
  final double draggableWidthFactor;
  final double draggableHeightFactor;
  final bool prewarmKeyboards;

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
  final GlobalKey _numericKeyboardKey = GlobalKey(debugLabel: 'numericKeyboard');

  late final TextEditingController _warmupController;
  late final FocusNode _warmupFocus;
  bool _panelsMounted = false;

  @override
  void initState() {
    super.initState();
    _warmupController = TextEditingController();
    _warmupFocus = FocusNode(
      skipTraversal: true,
      debugLabel: 'onscreenKeyboardWarmup',
    );
    if (useCustomOnscreenKeyboard && widget.prewarmKeyboards) {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        if (!mounted || _panelsMounted) return;
        setState(() => _panelsMounted = true);
      });
    }
  }

  @override
  void dispose() {
    _warmupController.dispose();
    _warmupFocus.dispose();
    super.dispose();
  }

  void _ensurePanelsMounted() {
    if (!_panelsMounted) {
      _panelsMounted = true;
    }
  }

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

    _ensurePanelsMounted();
    session.focusNode.requestFocus();

    if (!identical(previous, session)) {
      setState(() => _session = session);
    }

    clearOnscreenKeyboardValidation(session.focusNode);
  }

  void _dismiss() {
    if (!mounted) return;
    final previous = _session;
    if (previous != null) {
      clearOnscreenKeyboardValidation(previous.focusNode);
      previous.focusNode.unfocus();
    }
    if (_session != null) {
      setState(() => _session = null);
    }
    widget.onTapOutside?.call();
  }

  void _onEnter() {
    widget.onEnterPressed?.call();
    _dismiss();
  }

  OnscreenFieldSession get _fallbackSession => OnscreenFieldSession(
        controller: _warmupController,
        focusNode: _warmupFocus,
        keyboardType: TextInputType.text,
      );

  OnscreenFieldSession _sessionOrFallback(OnscreenFieldSession? session) =>
      session ?? _fallbackSession;

  @override
  Widget build(BuildContext context) {
    if (!useCustomOnscreenKeyboard) {
      return widget.child;
    }

    final session = _session;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final useDraggable =
        isLandscape && widget.useDraggableInLandscape && _panelsMounted;

    return _OnscreenKeyboardScope(
      state: this,
      child: useDraggable
          ? _buildDraggableShell(session)
          : _buildPortraitShell(session),
    );
  }

  Widget _buildDraggableShell(OnscreenFieldSession? session) {
    final active = _sessionOrFallback(session);
    final visible = session != null;

    return DraggableDynamicKeyboard(
      controller: active.controller,
      focusNode: active.focusNode,
      commitOnEnterOnly: widget.commitOnEnterOnly,
      useNumericKeyboard: active.useNumericKeyboard,
      numericMinValue: active.minValue,
      numericMaxValue: active.maxValue,
      minLength: active.useNumericKeyboard ? null : active.minLength,
      maxLength: active.useNumericKeyboard ? null : active.maxLength,
      validator: active.validator,
      widthFactor: widget.draggableWidthFactor,
      heightFactor: widget.draggableHeightFactor,
      fullWidthInLandscape: false,
      alwaysVisible: visible,
      pushContent: false,
      onTapOutside: _dismiss,
      onEnterPressed: _onEnter,
      child: widget.child,
    );
  }

  Widget _buildPortraitShell(OnscreenFieldSession? session) {
    return TapRegion(
      onTapOutside: (_) {
        if (session != null) {
          session.focusNode.unfocus();
        }
        _dismiss();
      },
      child: Column(
        children: [
          Expanded(child: widget.child),
          if (_panelsMounted) ...[
            _buildAlphaSlot(session),
            _buildNumericSlot(session),
          ],
        ],
      ),
    );
  }

  Widget _buildAlphaSlot(OnscreenFieldSession? session) {
    final active = _sessionOrFallback(session);
    final visible = session != null && !active.useNumericKeyboard;

    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      child: RepaintBoundary(
        child: CustomKeyboard(
          key: _alphaKeyboardKey,
          controller: active.controller,
          focusNode: active.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minLength: active.minLength,
          maxLength: active.maxLength,
          validator: active.validator,
          onTapOutside: _dismiss,
          onEnterPressed: _onEnter,
        ),
      ),
    );
  }

  Widget _buildNumericSlot(OnscreenFieldSession? session) {
    final active = _sessionOrFallback(session);
    final visible = session != null && active.useNumericKeyboard;

    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      child: RepaintBoundary(
        child: NumericKeyboard(
          key: _numericKeyboardKey,
          controller: active.controller,
          focusNode: active.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minValue: active.minValue,
          maxValue: active.maxValue,
          validator: active.validator,
          onTapOutside: _dismiss,
          onEnterPressed: _onEnter,
        ),
      ),
    );
  }
}
