import 'package:flutter/material.dart';

import '../core/keyboard_key_timing.dart';
import '../core/theme_controller.dart';
import 'keyboard_tap_target.dart';

class NumericKey extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isSpecial;
  final bool enableHoldRepeat;
  final KeyboardTheme theme;

  const NumericKey({
    super.key,
    required this.onTap,
    required this.child,
    required this.theme,
    this.isSpecial = false,
    this.enableHoldRepeat = false,
  });

  @override
  State<NumericKey> createState() => _NumericKeyState();
}

class _NumericKeyState extends State<NumericKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: KeyboardKeyTiming.pressAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final decoration = widget.isSpecial
        ? BoxDecoration(
            color: _isPressed ? t.keyPressedColor : t.specialKeyColor,
            borderRadius: BorderRadius.circular(t.borderRadius),
            border: Border.all(
              color: t.keyBorderColor,
              width: t.keyBorderWidth,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: t.shadowColor.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: t.shadowColor.withOpacity(0.4),
                      blurRadius: t.keyElevation * 2,
                      offset: Offset(0, t.keyElevation),
                    ),
                  ],
          )
        : BoxDecoration(
            gradient: _isPressed
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [t.keyPressedColor, t.keyPressedColor],
                  )
                : t.primaryGradient,
            borderRadius: BorderRadius.circular(t.borderRadius),
            border: Border.all(
              color: t.keyBorderColor,
              width: t.keyBorderWidth,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: t.shadowColor.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: t.shadowColor.withOpacity(0.4),
                      blurRadius: t.keyElevation * 2,
                      offset: Offset(0, t.keyElevation),
                    ),
                  ],
          );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: KeyboardTapTarget(
        onPressed: widget.onTap,
        enableHoldRepeat: widget.enableHoldRepeat,
        onPointerStateChanged: _setPressed,
        child: Container(
          height: 44,
          width: 45,
          decoration: decoration,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
