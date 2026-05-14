import 'package:flutter/material.dart';

import '../core/theme_controller.dart';

class NumericKey extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isSpecial;
  final KeyboardTheme theme;

  const NumericKey({
    super.key,
    required this.onTap,
    required this.child,
    required this.theme,
    this.isSpecial = false,
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
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final decoration = widget.isSpecial
        ? BoxDecoration(
            color: _isPressed ? t.activeKeyColor : t.specialKeyColor,
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
                    colors: [t.activeKeyColor, t.activeKeyColor],
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
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
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
