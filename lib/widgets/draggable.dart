import 'package:flutter/material.dart';

import '../core/keyboard_theme_resolver.dart';
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
  final num? numericMinValue;
  final num? numericMaxValue;
  final bool numericAllowDecimalInput;
  final bool numericIntegersOnly;

  /// Passed to [CustomKeyboard] when [useNumericKeyboard] is false.
  final int? maxLength;

  /// Passed to [CustomKeyboard] when [useNumericKeyboard] is false.
  final int? minLength;

  /// Passed to the active keyboard close button and outside dismiss.
  final VoidCallback onDismiss;

  /// When set, used instead of [ThemeController.keyboardTheme] for panel chrome
  /// and passed through to the child keyboard.
  final KeyboardTheme? keyboardTheme;

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
    this.numericAllowDecimalInput = true,
    this.numericIntegersOnly = false,
    this.maxLength,
    this.minLength,
    required this.onDismiss,
    this.keyboardTheme,
  });

  @override
  State<DraggableDynamicKeyboard> createState() =>
      _DraggableDynamicKeyboardState();
}

class _DraggableDynamicKeyboardState extends State<DraggableDynamicKeyboard> {
  static const double _edgeInset = 8.0;
  static const double _dragHandleHeight = 30.0;

  Offset _position = Offset.zero;

  final ValueNotifier<Offset> _positionNotifier = ValueNotifier(Offset.zero);

  bool _isVisible = false;

  /// Avoid showing the panel at [initialPosition] before layout centers it.
  bool _positionReady = false;

  double _panMinX = 0;
  double _panMaxX = 0;
  double _panMinY = 0;
  double _panMaxY = 0;
  Size _layoutArea = Size.zero;

  Size _keyboardSizeForArea(Size area) {
    if (widget.useNumericKeyboard) {
      final width = (area.width * widget.widthFactor)
          .clamp(260.0, area.width - 24)
          .toDouble();
      final height = (area.height * widget.heightFactor)
          .clamp(220.0, area.height - 24)
          .toDouble();
      return Size(width, height);
    }

    final width = widget.fullWidthInLandscape
        ? area.width
        : (area.width * widget.widthFactor)
            .clamp(280.0, area.width - 24)
            .toDouble();
    final height = (area.height * widget.heightFactor)
        .clamp(180.0, area.height - 24)
        .toDouble();
    return Size(width, height);
  }

  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(_onFocusChange);
    _isVisible = widget.alwaysVisible;

    if (_isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureKeyboardVisible();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DraggableDynamicKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _positionReady = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureKeyboardVisible();
      });
    }
  }

  void _onFocusChange() {
    final visible = widget.alwaysVisible || widget.focusNode.hasFocus;

    if (_isVisible == visible) return;

    setState(() => _isVisible = visible);

    if (visible) {
      _positionReady = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureKeyboardVisible();
      });
    }
  }

  void _ensureKeyboardVisible() {
    if (_layoutArea.width <= 0 || _layoutArea.height <= 0) return;

    final size = _keyboardSizeForArea(_layoutArea);
    const padding = 12.0;

    final maxX = (_layoutArea.width - size.width - padding)
        .clamp(padding, double.infinity)
        .toDouble();
    final maxY = (_layoutArea.height - size.height - padding)
        .clamp(padding, double.infinity)
        .toDouble();

    final offScreen = _position.dx < padding - 0.5 ||
        _position.dy < padding - 0.5 ||
        _position.dx > maxX + 0.5 ||
        _position.dy > maxY + 0.5;

    if (!_positionReady || offScreen) {
      _position = Offset(
        ((_layoutArea.width - size.width) / 2).clamp(padding, maxX).toDouble(),
        ((_layoutArea.height - size.height) / 2)
            .clamp(padding, maxY)
            .toDouble(),
      );
    } else {
      _position = Offset(
        _position.dx.clamp(padding, maxX).toDouble(),
        _position.dy.clamp(padding, maxY).toDouble(),
      );
    }

    _positionReady = true;
    _positionNotifier.value = _position;
    _cachePanBounds(size);
  }

  void _cachePanBounds([Size? keyboardSize]) {
    final area = _layoutArea;
    final size = keyboardSize ?? _keyboardSizeForArea(area);

    _panMinX = _edgeInset;
    _panMinY = _edgeInset;
    _panMaxX =
        (area.width - size.width - _edgeInset).clamp(_panMinX, double.infinity);
    _panMaxY = (area.height - size.height - _edgeInset)
        .clamp(_panMinY, double.infinity);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildKeyboardWithResolvedTheme(
      widgetOverride: widget.keyboardTheme,
      builder: (theme) => LayoutBuilder(
        builder: (context, constraints) {
          final newArea =
              Size(constraints.maxWidth, constraints.maxHeight);
          final areaChanged = newArea != _layoutArea;
          _layoutArea = newArea;

          if (areaChanged && (_isVisible || widget.alwaysVisible)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _ensureKeyboardVisible();
            });
          }

          final keyboardSize = _keyboardSizeForArea(_layoutArea);
          final keyboardPanel = RepaintBoundary(
            child: _buildKeyboardPanel(theme, keyboardSize),
          );

          final showPanel =
              (_isVisible || widget.alwaysVisible) && _positionReady;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (showPanel)
                ValueListenableBuilder<Offset>(
                  valueListenable: _positionNotifier,
                  builder: (context, position, _) {
                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: keyboardPanel,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKeyboardPanel(KeyboardTheme theme, Size keyboardSize) {
    final panelHeight = keyboardSize.height;
    final keysHeight = panelHeight - _dragHandleHeight;

    return Material(
      color: Colors.transparent,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: keyboardSize.width,
        height: panelHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: widget.useNumericKeyboard
                    ? NumericKeyboard(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        onEnterPressed: widget.onEnterPressed,
                        onSubmitted: widget.onSubmitted,
                        validator: widget.validator,
                        commitOnEnterOnly: widget.commitOnEnterOnly,
                        height: keysHeight,
                        minValue: widget.numericMinValue,
                        maxValue: widget.numericMaxValue,
                        allowDecimalInput: widget.numericAllowDecimalInput,
                        integersOnly: widget.numericIntegersOnly,
                        maxLength: widget.maxLength,
                        onDismiss: widget.onDismiss,
                        keyboardTheme: theme,
                      )
                    : CustomKeyboard(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        onEnterPressed: widget.onEnterPressed,
                        onSubmitted: widget.onSubmitted,
                        validator: widget.validator,
                        commitOnEnterOnly: widget.commitOnEnterOnly,
                        height: keysHeight,
                        maxLength: widget.maxLength,
                        minLength: widget.minLength,
                        onDismiss: widget.onDismiss,
                        keyboardTheme: theme,
                      ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => _cachePanBounds(),
                onPanUpdate: (details) {
                  final nx = (_position.dx + details.delta.dx)
                      .clamp(_panMinX, _panMaxX)
                      .toDouble();
                  final ny = (_position.dy + details.delta.dy)
                      .clamp(_panMinY, _panMaxY)
                      .toDouble();
                  _position = Offset(nx, ny);
                  _positionNotifier.value = _position;
                },
                child: Container(
                  height: _dragHandleHeight,
                  decoration: BoxDecoration(
                    color: theme.specialKeyColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.keyTextColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
