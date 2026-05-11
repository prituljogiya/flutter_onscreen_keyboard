import 'package:flutter/material.dart';

import '../core/theme_controller.dart';

class DualKey extends StatefulWidget {
  final String topChar;
  final String bottomChar;
  final VoidCallback onTap;
  final VoidCallback? onLongPressKey;
  final List<String>? alternateChars;
  final ValueChanged<String>? onAlternateSelected;
  final KeyboardTheme theme;
  final double? width;
  final double? height;

  const DualKey({
    super.key,
    required this.topChar,
    required this.bottomChar,
    required this.onTap,
    this.onLongPressKey,
    this.alternateChars,
    this.onAlternateSelected,
    required this.theme,
    this.width,
    this.height,
  });

  @override
  State<DualKey> createState() => _DualKeyState();
}

class _DualKeyState extends State<DualKey> with SingleTickerProviderStateMixin {
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(10),
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
    final keyHeight = widget.height ?? 48;
    final topFontSize = (keyHeight * 0.24).clamp(10.0, 13.0);
    final bottomFontSize = (keyHeight * 0.28).clamp(11.0, 15.0);
    final verticalGap = keyHeight < 36 ? 0.0 : 2.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: _handleLongPress,
        child: Container(
          width: widget.width,
          height: widget.height ?? 48,
          margin: EdgeInsets.all(widget.theme.keySpacing / 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isPressed
                  ? [const Color(0xFF2D0A4A), const Color(0xFF1A0530)]
                  : [const Color(0xFF4A1A6B), const Color(0xFF2D0A4A)],
            ),
            borderRadius: BorderRadius.circular(widget.theme.borderRadius),
            border: Border.all(
              color: widget.theme.keyBorderColor,
              width: widget.theme.keyBorderWidth,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.topChar,
                        maxLines: 1,
                        style: TextStyle(
                          color: const Color(0xFF00E5D4),
                          fontSize: topFontSize,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: verticalGap),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.bottomChar,
                        maxLines: 1,
                        style: TextStyle(
                          color: const Color(0xFFE0D0FF),
                          fontSize: bottomFontSize,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
