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

  /// Passed to [CustomKeyboard] when [useNumericKeyboard] is false.
  final int? maxLength;

  /// Passed to [CustomKeyboard] when [useNumericKeyboard] is false.
  final int? minLength;

  /// Passed to the active keyboard; runs after unfocus on outside tap.
  final VoidCallback? onTapOutside;

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
    this.maxLength,
    this.minLength,
    this.onTapOutside,
    this.keyboardTheme,
  });

  @override
  State<DraggableDynamicKeyboard> createState() =>
      _DraggableDynamicKeyboardState();
}

class _DraggableDynamicKeyboardState extends State<DraggableDynamicKeyboard> {
  late Offset _position;

  final ValueNotifier<Offset> _positionNotifier = ValueNotifier(Offset.zero);

  bool _isVisible = false;

  double _panMinX = 0;
  double _panMaxX = 0;
  double _panMinY = 0;
  double _panMaxY = 0;
  bool _hasPositionedInitially = false;
  Size _layoutArea = Size.zero;

  late Widget _keyboardPanel;

  @override
  void initState() {
    super.initState();

    _position = widget.initialPosition;
    _positionNotifier.value = _position;

    widget.focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isVisible || widget.alwaysVisible) {
        _ensureKeyboardVisible();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableDynamicKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    final visible = widget.alwaysVisible || widget.focusNode.hasFocus;

    if (_isVisible != visible) {
      setState(() {
        _isVisible = visible;
      });

      if (visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureKeyboardVisible();
        });
      }
    }
  }

  //
  //
  // //
  // void _ensureKeyboardVisible() {
  //   final keyboardWidth = widget.useNumericKeyboard
  //       ? 360.0
  //       : _keyboardWidthForScreen(_layoutArea);
  //
  //   final keyboardHeight = widget.useNumericKeyboard
  //       ? 400.0
  //       : _keyboardHeightForScreen(_layoutArea);
  //
  //   const padding = 12.0;
  //
  //   final maxX = (_layoutArea.width - keyboardWidth - padding).clamp(
  //     padding,
  //     double.infinity,
  //   );
  //
  //   final maxY = (_layoutArea.height - keyboardHeight - padding).clamp(
  //     padding,
  //     double.infinity,
  //   );
  //
  //
  //   /// FIRST TIME → OPEN IN CENTER
  //   if (!_hasPositionedInitially) {
  //     _hasPositionedInitially = true;
  //
  //     _position = Offset(
  //       (_layoutArea.width - keyboardWidth) / 2,
  //       (_layoutArea.height - keyboardHeight) / 2,
  //     );
  //
  //     _positionNotifier.value = _position;
  //     return;
  //   }
  //
  //   /// If keyboard is outside screen,
  //   /// reposition it automatically.
  //   final shouldResetPosition =
  //       _position.dy > maxY || _position.dx > maxX;
  //
  //   if (shouldResetPosition) {
  //     _position = Offset(padding, maxY.toDouble());
  //
  //     _positionNotifier.value = _position;
  //     return;
  //   }
  //
  //   final corrected = Offset(
  //     _position.dx.clamp(padding, maxX).toDouble(),
  //     _position.dy.clamp(padding, maxY).toDouble(),
  //   );
  //
  //   if (corrected != _position) {
  //     _position = corrected;
  //     _positionNotifier.value = corrected;
  //   }
  // //   /// If keyboard is outside screen,
  // //   /// reposition it automatically.
  // //   final shouldResetPosition = _position.dy > maxY || _position.dx > maxX;
  // //
  // //   if (shouldResetPosition) {
  // //     _position = Offset(padding, maxY.toDouble());
  // //
  // //     _positionNotifier.value = _position;
  // //     return;
  // //   }
  // //
  // //   final corrected = Offset(
  // //     _position.dx.clamp(padding, maxX).toDouble(),
  // //     _position.dy.clamp(padding, maxY).toDouble(),
  // //   );
  // //
  // //   if (corrected != _position) {
  // //     _position = corrected;
  // //     _positionNotifier.value = corrected;
  // //   }
  // // }

  void _ensureKeyboardVisible() {
    final keyboardWidth = widget.useNumericKeyboard ? 207.0 : 761.0;

    final keyboardHeight = widget.useNumericKeyboard ? 400.0 : 327.0;

    const padding = 12.0;

    final maxX = (_layoutArea.width - keyboardWidth - padding).clamp(
      padding,
      double.infinity,
    );

    final maxY = (_layoutArea.height - keyboardHeight - padding).clamp(
      padding,
      double.infinity,
    );

    /// FIRST TIME → OPEN IN CENTER
    if (!_hasPositionedInitially) {
      _hasPositionedInitially = true;

      _position = Offset(
        (_layoutArea.width - keyboardWidth) / 2,
        (_layoutArea.height - keyboardHeight) / 2,
      );

      _positionNotifier.value = _position;
      return;
    }

    /// If keyboard is outside screen,
    /// reposition it automatically.
    final shouldResetPosition = _position.dy > maxY || _position.dx > maxX;

    if (shouldResetPosition) {
      _position = Offset(padding, maxY.toDouble());

      _positionNotifier.value = _position;
      return;
    }

    final corrected = Offset(
      _position.dx.clamp(padding, maxX).toDouble(),
      _position.dy.clamp(padding, maxY).toDouble(),
    );

    if (corrected != _position) {
      _position = corrected;
      _positionNotifier.value = corrected;
    }
  }

  void _cachePanBounds() {
    final area = _layoutArea;

    final keyboardWidth = widget.useNumericKeyboard ? 207.0 : 761.0;

    final keyboardHeight = widget.useNumericKeyboard ? 366.0 : 327.0;

    const minX = 8.0;
    const minY = 8.0;

    _panMinX = minX;
    _panMinY = minY;

    _panMaxX = (area.width - keyboardWidth - 8).clamp(minX, double.infinity);

    _panMaxY = (area.height - keyboardHeight - 8).clamp(minY, double.infinity);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final nx =
    (_position.dx + event.delta.dx).clamp(_panMinX, _panMaxX).toDouble();

    final ny =
    (_position.dy + event.delta.dy).clamp(_panMinY, _panMaxY).toDouble();

    if (nx == _position.dx && ny == _position.dy) return;

    _position = Offset(nx, ny);

    _positionNotifier.value = _position;
  }

  double _keyboardWidthForScreen(Size area) {
    return (area.width * widget.widthFactor)
        .clamp(280.0, area.width - 24)
        .toDouble();
  }

  double _keyboardHeightForScreen(Size area) {
    return (area.height * widget.heightFactor)
        .clamp(180.0, area.height - 24)
        .toDouble();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildWithTheme(KeyboardTheme theme) {
      return LayoutBuilder(
        builder: (context, constraints) {
          _layoutArea = Size(constraints.maxWidth, constraints.maxHeight);

          _cachePanBounds();

          final keyboardWidth = widget.useNumericKeyboard ? 207.0 : 761.0;

          final keyboardHeight = widget.useNumericKeyboard ? 366.0 : 327.0;

          _keyboardPanel = RepaintBoundary(
            child: _buildKeyboardPanel(theme, keyboardWidth, keyboardHeight),
          );

          return Stack(
            children: [
              widget.child,
              if (_isVisible || widget.alwaysVisible)
                ValueListenableBuilder<Offset>(
                  valueListenable: _positionNotifier,
                  builder: (context, position, _) {
                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: Listener(
                        child: _keyboardPanel,
                      ),
                    );
                  },
                ),
            ],
          );
        },
      );
    }

    if (widget.keyboardTheme != null) {
      return buildWithTheme(widget.keyboardTheme!);
    }
    if (!Get.isRegistered<ThemeController>()) {
      return buildWithTheme(KeyboardTheme.purpleCyan());
    }
    return Obx(() {
      Get.find<ThemeController>().keyboardThemeRx.value;
      return buildWithTheme(Get.find<ThemeController>().keyboardTheme);
    });
  }

  Widget _buildKeyboardPanel(KeyboardTheme theme,
      double keyboardWidth,
      double keyboardHeight,) {
    return Material(
      color: Colors.transparent,

      /// FIXED ELEVATION
      elevation: 1,

      borderRadius: BorderRadius.circular(16),

      child: Container(
        width: keyboardWidth,
        height: keyboardHeight,
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
                height: keyboardHeight,
                minValue: widget.numericMinValue,
                maxValue: widget.numericMaxValue,
                onTapOutside: widget.onTapOutside,
                keyboardTheme: theme,
              )
                  : CustomKeyboard(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onEnterPressed: widget.onEnterPressed,
                onSubmitted: widget.onSubmitted,
                validator: widget.validator,
                commitOnEnterOnly: widget.commitOnEnterOnly,
                height: keyboardHeight,
                maxLength: widget.maxLength,
                minLength: widget.minLength,
                onTapOutside: widget.onTapOutside,
                keyboardTheme: theme,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {
                _cachePanBounds();
              },
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
                height: 30,
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
    );
  }
}