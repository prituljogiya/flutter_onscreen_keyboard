import 'dart:async';

import 'package:flutter/material.dart';

import '../core/keyboard_key_timing.dart';

/// Pointer-down handling aligned with the system keyboard: action on touch,
/// optional hold-to-repeat, long-press for alternates.
class KeyboardTapTarget extends StatefulWidget {
  const KeyboardTapTarget({
    super.key,
    required this.child,
    required this.onPressed,
    this.fireOnRelease = false,
    this.enableHoldRepeat = false,
    this.onLongPress,
    this.onPointerStateChanged,
  });

  final Widget child;
  final VoidCallback onPressed;

  /// Called with `true` on touch down and `false` on up/cancel (key highlight).
  final ValueChanged<bool>? onPointerStateChanged;

  /// Accent / alternate keys: fire [onPressed] on finger up if long-press did not run.
  final bool fireOnRelease;

  /// Backspace-style repeat after [KeyboardKeyTiming.repeatInitialDelay].
  final bool enableHoldRepeat;

  final VoidCallback? onLongPress;

  @override
  State<KeyboardTapTarget> createState() => _KeyboardTapTargetState();
}

class _KeyboardTapTargetState extends State<KeyboardTapTarget> {
  Timer? _holdDelay;
  Timer? _holdRepeat;
  Timer? _longPressTimer;
  bool _pointerDown = false;
  bool _longPressFired = false;

  @override
  void dispose() {
    _stopHoldRepeat();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _stopHoldRepeat() {
    _holdDelay?.cancel();
    _holdRepeat?.cancel();
    _holdDelay = null;
    _holdRepeat = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = true;
    _longPressFired = false;
    widget.onPointerStateChanged?.call(true);

    if (!widget.fireOnRelease) {
      widget.onPressed();
    }

    if (widget.enableHoldRepeat) {
      _holdDelay = Timer(KeyboardKeyTiming.repeatInitialDelay, () {
        if (!_pointerDown) return;
        _holdRepeat = Timer.periodic(KeyboardKeyTiming.repeatInterval, (_) {
          if (_pointerDown) widget.onPressed();
        });
      });
    }

    final onLongPress = widget.onLongPress;
    if (onLongPress != null) {
      _longPressTimer = Timer(KeyboardKeyTiming.longPressDelay, () {
        if (!_pointerDown) return;
        _longPressFired = true;
        _stopHoldRepeat();
        onLongPress();
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerDown = false;
    widget.onPointerStateChanged?.call(false);
    _stopHoldRepeat();
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (widget.fireOnRelease && !_longPressFired) {
      widget.onPressed();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDown = false;
    widget.onPointerStateChanged?.call(false);
    _stopHoldRepeat();
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
