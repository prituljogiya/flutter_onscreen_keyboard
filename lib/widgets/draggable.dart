import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme_controller.dart';
import 'custom_keyboard.dart';
import 'numeric.dart';

class DraggableDynamicKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;
  final VoidCallback? onEnterPressed;
  final String? Function(String)? validator;
  final Offset initialPosition;
  final bool showDragHandle;
  final bool snapToEdges;
  final bool pushContent;
  final Duration animationDuration;
  final ValueChanged<String>? onSubmitted;
  final bool commitOnEnterOnly;
  final double widthFactor;
  final double heightFactor;
  final bool fullWidthInLandscape;
  final bool alwaysVisible;
  final bool useNumericKeyboard;
  final int? numericMinValue;
  final int? numericMaxValue;

  const DraggableDynamicKeyboard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.child,
    this.onEnterPressed,
    this.validator,
    this.initialPosition = const Offset(50, 400),
    this.showDragHandle = true,
    this.snapToEdges = true,
    this.pushContent = true,
    this.animationDuration = const Duration(milliseconds: 250),
    this.onSubmitted,
    this.commitOnEnterOnly = true,
    this.widthFactor = 0.5,
    this.heightFactor = 0.5,
    this.fullWidthInLandscape = true,
    this.alwaysVisible = false,
    this.useNumericKeyboard = false,
    this.numericMinValue,
    this.numericMaxValue,
  });

  @override
  State<DraggableDynamicKeyboard> createState() =>
      _DraggableDynamicKeyboardState();
}

class _DraggableDynamicKeyboardState extends State<DraggableDynamicKeyboard> {
  late Offset _position;
  late final ValueNotifier<Offset> _positionNotifier;
  late final ValueNotifier<bool> _draggingNotifier;

  bool _isVisible = false;
  double _contentPadding = 0;

  /// Last laid-out area for the overlay (e.g. inside [SafeArea]); avoids using
  /// full [MediaQuery.size] which is taller than the stack and clips the panel.
  Size _layoutArea = Size.zero;

  /// When true, next snap places the panel fully on-screen (bottom-aligned).
  bool _alignBottomWhenSnap = true;

  /// Cached during active pan — avoids MediaQuery + layout math every move event.
  double? _panMinX;
  double? _panMaxX;
  double? _panMinY;
  double? _panMaxY;

  @override
  void initState() {
    super.initState();

    _position = widget.initialPosition;
    _positionNotifier = ValueNotifier(_position);
    _draggingNotifier = ValueNotifier(false);

    widget.focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onFocusChange();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableDynamicKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onFocusChange();
      });
    }
  }

  void _onFocusChange() {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final keyboardHeight = _keyboardHeightForScreen(screen);

    setState(() {
      _isVisible = widget.alwaysVisible || widget.focusNode.hasFocus;

      if (_isVisible && widget.pushContent) {
        _contentPadding = keyboardHeight + 20;
      } else {
        _contentPadding = 0;
      }
    });

    if (_isVisible) {
      _alignBottomWhenSnap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _snapToEdges();
      });
      _scrollToField();
    }
  }

  void _scrollToField() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && widget.focusNode.hasFocus) {
        final context = widget.focusNode.context;

        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: widget.animationDuration,
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          );
        }
      }
    });
  }

  double _totalPanelHeight(Size area) {
    final keyboardHeight = _keyboardHeightForScreen(area);
    return keyboardHeight + (widget.showDragHandle ? 32 : 0);
  }

  Size _areaForBounds() {
    if (_layoutArea.width > 0 && _layoutArea.height > 0) {
      return _layoutArea;
    }
    return MediaQuery.sizeOf(context);
  }

  void _cachePanBounds() {
    final area = _areaForBounds();
    final keyboardWidth = _keyboardWidthForScreen(area);
    final totalHeight = _totalPanelHeight(area);
    final bounds = _dragBounds(area, keyboardWidth, totalHeight);
    _panMinX = bounds.$1;
    _panMaxX = bounds.$2;
    _panMinY = bounds.$3;
    _panMaxY = bounds.$4;
  }

  void _clearPanBounds() {
    _panMinX = null;
    _panMaxX = null;
    _panMinY = null;
    _panMaxY = null;
  }

  void _onPanStart(DragStartDetails details) {
    _cachePanBounds();
    if (!_draggingNotifier.value) {
      _draggingNotifier.value = true;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panMinX == null ||
        _panMaxX == null ||
        _panMinY == null ||
        _panMaxY == null) {
      _cachePanBounds();
    }

    final nx = (_position.dx + details.delta.dx)
        .clamp(_panMinX!, _panMaxX!)
        .toDouble();
    final ny = (_position.dy + details.delta.dy)
        .clamp(_panMinY!, _panMaxY!)
        .toDouble();
    final newOffset = Offset(nx, ny);

    _position = newOffset;
    _positionNotifier.value = newOffset;
  }

  void _onPanEnd(DragEndDetails details) {
    _clearPanBounds();
    if (_draggingNotifier.value) {
      _draggingNotifier.value = false;
    }
    if (widget.snapToEdges) {
      _snapToEdges();
    }
  }

  void _snapToEdges() {
    final area = _areaForBounds();
    final keyboardWidth = _keyboardWidthForScreen(area);
    final totalHeight = _totalPanelHeight(area);
    final bounds = _dragBounds(area, keyboardWidth, totalHeight);
    final minX = bounds.$1;
    final maxX = bounds.$2;
    final minY = bounds.$3;
    final maxY = bounds.$4;

    setState(() {
      if (_alignBottomWhenSnap) {
        final centerX = (minX + maxX) / 2 - keyboardWidth / 2;
        final x = centerX.clamp(minX, maxX).toDouble();
        _position = Offset(x, maxY);
        _alignBottomWhenSnap = false;
      } else {
        _position = Offset(
          _position.dx.clamp(minX, maxX).toDouble(),
          _position.dy.clamp(minY, maxY).toDouble(),
        );
      }
      _positionNotifier.value = _position;
    });
  }

  double _keyboardWidthForScreen(Size area) {
    final isLandscape = area.width > area.height;
    if (widget.fullWidthInLandscape && isLandscape) {
      return (area.width - 24).clamp(280.0, area.width).toDouble();
    }
    return (area.width * widget.widthFactor)
        .clamp(280.0, area.width - 24)
        .toDouble();
  }

  double _keyboardHeightForScreen(Size area) {
    return (area.height * widget.heightFactor)
        .clamp(180.0, area.height - 24)
        .toDouble();
  }

  (double, double, double, double) _dragBounds(
    Size area,
    double keyboardWidth,
    double totalPanelHeight,
  ) {
    const minX = 8.0;
    const minY = 8.0;
    final computedMaxX = (area.width - keyboardWidth - 8).toDouble();
    final computedMaxY = (area.height - totalPanelHeight - 8).toDouble();
    final maxX = computedMaxX < minX ? minX : computedMaxX;
    final maxY = computedMaxY < minY ? minY : computedMaxY;
    return (minX, maxX, minY, maxY);
  }

  @override
  void dispose() {
    _draggingNotifier.dispose();
    _positionNotifier.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final theme = themeController.keyboardTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutArea = Size(constraints.maxWidth, constraints.maxHeight);

        final area = _layoutArea;
        final keyboardWidth = _keyboardWidthForScreen(area);
        final keyboardHeight = _keyboardHeightForScreen(area);
        final totalPanelHeight = _totalPanelHeight(area);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPadding(
              duration: widget.animationDuration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: _contentPadding),
              child: widget.child,
            ),

            if (_isVisible || widget.alwaysVisible)
              ValueListenableBuilder<Offset>(
                valueListenable: _positionNotifier,
                builder: (context, position, _) {
                  return Transform.translate(
                    offset: position,
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _draggingNotifier,
                        builder: (context, dragging, __) {
                          return Material(
                            color: Colors.transparent,
                            elevation: dragging ? 0 : 10,
                            shadowColor: dragging
                                ? Colors.transparent
                                : Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: keyboardWidth,
                              height: totalPanelHeight,
                              decoration: BoxDecoration(
                                color: theme.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  if (widget.showDragHandle)
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: _onPanStart,
                                      onPanUpdate: _onPanUpdate,
                                      onPanEnd: _onPanEnd,
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: theme.specialKeyColor,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: theme.keyTextColor
                                                  .withOpacity(0.35),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: widget.useNumericKeyboard
                                          ? NumericKeyboard(
                                              controller: widget.controller,
                                              focusNode: widget.focusNode,
                                              onEnterPressed:
                                                  widget.onEnterPressed,
                                              onSubmitted: widget.onSubmitted,
                                              validator: widget.validator,
                                              commitOnEnterOnly:
                                                  widget.commitOnEnterOnly,
                                              height: keyboardHeight,
                                              minValue: widget.numericMinValue,
                                              maxValue: widget.numericMaxValue,
                                            )
                                          : CustomKeyboard(
                                              controller: widget.controller,
                                              focusNode: widget.focusNode,
                                              onEnterPressed:
                                                  widget.onEnterPressed,
                                              onSubmitted: widget.onSubmitted,
                                              validator: widget.validator,
                                              commitOnEnterOnly:
                                                  widget.commitOnEnterOnly,
                                              height: keyboardHeight,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
