import 'package:flutter/material.dart';

import '../core/theme_controller.dart';

class KeyboardKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPressKey;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool isSpecial;
  final bool isActive;
  /// Second-level Caps state (e.g. accent border).
  final bool isSubActive;
  final bool isFlashHighlight;
  final bool isWide;
  final double? width;
  final double? height;
  final List<String>? alternateChars;
  final ValueChanged<String>? onAlternateSelected;
  final KeyboardTheme theme;

  const KeyboardKey({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPressKey,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.isSpecial = false,
    this.isActive = false,
    this.isSubActive = false,
    this.isFlashHighlight = false,
    this.isWide = false,
    this.width,
    this.height,
    this.alternateChars,
    this.onAlternateSelected,
    required this.theme,
  });

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
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

  void _handleLongPress() {
    if (widget.alternateChars != null && widget.alternateChars!.isNotEmpty) {
      _showAlternateChars();
      return;
    }
    widget.onLongPressKey?.call();
  }

  void _showAlternateChars() {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _removeOverlay,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx - 60,
            top: position.dy - 70,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 44,
                width: 45,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.theme.keyBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.alternateChars!.map((char) {
                    return GestureDetector(
                      onTap: () {
                        widget.onAlternateSelected?.call(char);
                        _removeOverlay();
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          color: widget.theme.activeKeyColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          char,
                          style: TextStyle(
                            fontSize: 20,
                            color: widget.theme.keyTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isSpecial = widget.isSpecial || widget.isActive;

    Color bgColor;
    Color textColor;
    Gradient? gradient;

    if (widget.isFlashHighlight) {
      bgColor = widget.theme.activeKeyColor.withOpacity(0.92);
      textColor = widget.theme.specialKeyTextColor;
    } else if (widget.isActive) {
      bgColor = widget.theme.activeKeyColor;
      textColor = widget.theme.specialKeyTextColor;
    } else if (isSpecial) {
      bgColor = widget.theme.specialKeyColor;
      textColor = widget.theme.specialKeyTextColor;
    } else {
      bgColor = widget.theme.keyBackgroundColor;
      textColor = widget.theme.keyTextColor;
      gradient = widget.theme.primaryGradient;
    }

    Widget keyContent;

    if (widget.label == 'BACKSPACE') {
      keyContent = Icon(Icons.backspace_outlined, color: textColor, size: 20);
    } else if (widget.label == 'ENTER') {
      keyContent =  Text(
        "Enter",
        style: TextStyle(
          color: textColor,
          fontSize: widget.theme.fontSize,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (widget.label == 'LEFT ARROW') {
      keyContent = Icon(Icons.arrow_back, color: textColor, size: 20);
    } else if (widget.label == 'RIGHT ARROW') {
      keyContent = Icon(Icons.arrow_forward, color: textColor, size: 20);
    } else if (widget.label == 'SHIFT') {
      keyContent = Text(
        "Shift",
        style: TextStyle(
          color: textColor,
          fontSize: widget.theme.fontSize,
          fontWeight: FontWeight.normal,
        ),
      );
    } else if (widget.label == 'CAPS') {
      keyContent = Text(
        "Caps",
        style: TextStyle(
          color: textColor,
          fontSize: widget.theme.fontSize - 1,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (widget.label == 'SPACE') {
      keyContent = Container(
        width: double.infinity,
        height: 4,
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          "SPACE",
          style: TextStyle(
            color: textColor,
            fontSize: widget.theme.fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (widget.label == '123' || widget.label == 'ABC') {
      keyContent = Text(
        widget.label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      keyContent = Text(
        widget.label,
        style: TextStyle(
          color: textColor,
          fontSize: widget.theme.fontSize,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: _handleLongPress,
        onLongPressStart: (_) => widget.onLongPressStart?.call(),
        onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
        child: Container(
          width: widget.width,
          height: widget.height ?? widget.width ?? 48,
          margin: EdgeInsets.all(widget.theme.keySpacing / 2),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? bgColor : null,
            borderRadius: BorderRadius.circular(widget.theme.borderRadius),
            border: Border.all(
              color: widget.isFlashHighlight
                  ? const Color(0xFF00E5D4)
                  : widget.isSubActive
                      ? const Color(0xFFFFB74D)
                      : widget.theme.keyBorderColor,
              width: (widget.isFlashHighlight || widget.isSubActive)
                  ? 2.2
                  : widget.theme.keyBorderWidth,
            ),
            boxShadow: _isPressed
                ? [
              BoxShadow(
                color: widget.theme.shadowColor.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ]
                : [
              BoxShadow(
                color: widget.theme.shadowColor.withOpacity(0.4),
                blurRadius: widget.theme.keyElevation * 2,
                offset: Offset(0, widget.theme.keyElevation),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: keyContent,
        ),
      ),
    );
  }
}
