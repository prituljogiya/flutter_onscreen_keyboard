import 'package:flutter/material.dart';

import '../core/keyboard_key_timing.dart';
import '../core/theme_controller.dart';
import 'keyboard_tap_target.dart';

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
  /// When true, the character that is inserted on tap is shown larger/brighter.
  final bool primaryIsTop;

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
    this.primaryIsTop = false,
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
      duration: KeyboardKeyTiming.pressAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(DualKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryIsTop != widget.primaryIsTop) {
      setState(() {});
    }
  }

  bool get _hasAlternates =>
      widget.alternateChars != null && widget.alternateChars!.isNotEmpty;

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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
    final topScale = widget.primaryIsTop ? 1.12 : 0.92;
    final bottomScale = widget.primaryIsTop ? 0.92 : 1.12;
    final topFontSize = (keyHeight * 0.24 * topScale).clamp(10.0, 16.0);
    final bottomFontSize = (keyHeight * 0.28 * bottomScale).clamp(11.0, 17.0);
    final topWeight =
        widget.primaryIsTop ? FontWeight.w800 : FontWeight.w600;
    final bottomWeight =
        widget.primaryIsTop ? FontWeight.w500 : FontWeight.w700;
    final topOpacity = widget.primaryIsTop ? 1.0 : 0.55;
    final bottomOpacity = widget.primaryIsTop ? 0.55 : 1.0;
    final verticalGap = keyHeight < 36 ? 0.0 : 2.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: KeyboardTapTarget(
        onPressed: widget.onTap,
        fireOnRelease: _hasAlternates,
        onPointerStateChanged: _setPressed,
        onLongPress: (_hasAlternates || widget.onLongPressKey != null)
            ? _handleLongPress
            : null,
        child: Container(
          width: widget.width,
          height: widget.height ?? 48,
          margin: EdgeInsets.all(widget.theme.keySpacing / 2),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.theme.keyPressedColor,
                      widget.theme.keyPressedColor,
                    ],
                  )
                : widget.theme.primaryGradient,
            borderRadius: BorderRadius.circular(widget.theme.borderRadius),
            border: Border.all(
              color: _isPressed
                  ? widget.theme.keyPressedColor
                  : widget.theme.keyBorderColor,
              width: _isPressed
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
                          color: widget.theme.specialKeyTextColor
                              .withOpacity(topOpacity),
                          fontSize: topFontSize,
                          fontWeight: topWeight,
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
                          color: widget.theme.keyTextColor
                              .withOpacity(bottomOpacity),
                          fontSize: bottomFontSize,
                          fontWeight: bottomWeight,
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
