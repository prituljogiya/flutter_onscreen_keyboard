import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/keyboard_controller.dart';
import '../core/theme_controller.dart';
import 'duelKey.dart';
import 'keyboardkey.dart';

class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onEnterPressed;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String)? validator;
  final bool commitOnEnterOnly;
  final double? height;

  const CustomKeyboard({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onEnterPressed,
    this.onSubmitted,
    this.validator,
    this.commitOnEnterOnly = false,
    this.height,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  late KeyboardController _keyboardController;
  late TextEditingController _inputController;
  late bool _ownsInputController;
  Timer? _backspaceTimer;

  @override
  void initState() {
    super.initState();
    _ownsInputController = widget.commitOnEnterOnly;
    _inputController = _ownsInputController
        ? TextEditingController(text: widget.controller.text)
        : widget.controller;
    _initController();
  }

  void _initController() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<KeyboardController>(tag: tag)) {
      _keyboardController = Get.find<KeyboardController>(tag: tag);
    } else {
      _keyboardController = KeyboardController(
        textController: _inputController,
        focusNode: widget.focusNode,
        validator: widget.validator,
      );
      Get.put(_keyboardController, tag: tag);
    }
  }

  @override
  void didUpdateWidget(covariant CustomKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.commitOnEnterOnly) {
      _inputController.text = widget.controller.text;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    }
  }

  @override
  void dispose() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<KeyboardController>(tag: tag)) {
      Get.delete<KeyboardController>(tag: tag);
    }
    _stopContinuousBackspace();
    if (_ownsInputController) {
      _inputController.dispose();
    }
    super.dispose();
  }

  void _startContinuousBackspace() {
    _keyboardController.backspace();
    _backspaceTimer?.cancel();
    _backspaceTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      _keyboardController.backspace();
    });
  }

  void _stopContinuousBackspace() {
    _backspaceTimer?.cancel();
    _backspaceTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeyboardTheme.purpleCyan();
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final isLandscape = media.orientation == Orientation.landscape;
    final keyboardHeight =
        widget.height ?? screenSize.height * (isLandscape ? 0.58 : 0.45);

    return Obx(() {
      final layout = _keyboardController.currentLayout;

      return Container(
        height: keyboardHeight,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewHeight = isLandscape ? 38.0 : 48.0;
            final previewMargin = isLandscape ? 6.0 : 8.0;
            final horizontalPadding = isLandscape ? 3.0 : 4.0;
            final validationHeight = _keyboardController.validationError == null
                ? 0.0
                : 22.0;

            // Keys add vertical margin (keySpacing) outside [height] — must fit inside row.
            final keyVertInset = theme.keySpacing;
            const layoutSafety = 2.0;

            final previewBlock =
                previewHeight + (previewMargin * 2) + layoutSafety;
            final availableForRows =
                (constraints.maxHeight - previewBlock - validationHeight).clamp(
                  0.0,
                  double.infinity,
                );

            final rowCount = layout.length;
            final maxPerRow = rowCount > 0
                ? availableForRows / rowCount
                : availableForRows;

            // Never clamp *up* past available space (that caused bottom overflow in landscape).
            final maxRowCap = isLandscape ? 44.0 : 56.0;
            final rowHeight = maxPerRow > maxRowCap ? maxRowCap : maxPerRow;

            final keyBodyHeight = (rowHeight - keyVertInset).clamp(
              0.0,
              rowHeight,
            );

            return Column(
              children: [
                Container(
                  height: previewHeight,
                  margin: EdgeInsets.all(previewMargin),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 10 : 12,
                  ),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: _inputController,
                    builder: (context, TextEditingValue value, child) {
                      return Text(
                        value.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLandscape ? 16 : 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                if (_keyboardController.validationError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _keyboardController.validationError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildAlphanumericKeyboard(
                    layout,
                    theme,
                    rowHeight: rowHeight,
                    keyBodyHeight: keyBodyHeight,
                    horizontalPadding: horizontalPadding,
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildAlphanumericKeyboard(
    List<List<String>> layout,
    KeyboardTheme theme, {
    required double rowHeight,
    required double keyBodyHeight,
    required double horizontalPadding,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: layout.map((row) {
        return SizedBox(
          height: rowHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return _buildKey(
                  key,
                  theme,
                  row.length,
                  rowHeight: rowHeight,
                  keyBodyHeight: keyBodyHeight,
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(
    String key,
    KeyboardTheme theme,
    int rowKeyCount, {
    required double rowHeight,
    required double keyBodyHeight,
  }) {
    bool isSpecial = false;
    bool isActive = false;
    bool isWide = false;
    double? width;
    bool isDual = false;
    String topChar = '';
    String bottomChar = '';
    VoidCallback onTap;
    List<String>? alternates;
    ValueChanged<String>? onAlternate;

    if (key.contains('|')) {
      final parts = key.split('|');
      if (parts.length == 2) {
        isDual = true;
        bottomChar = parts[0];
        topChar = parts[1];
      }
    }

    switch (key) {
      case 'SHIFT':
        isSpecial = true;
        isActive = _keyboardController.isShiftActive;
        width = 76;
        onTap = () {
          _keyboardController.toggleShift();
        };
        break;
      case 'CAPS':
        isSpecial = true;
        isActive = _keyboardController.isCapsLock;
        width = 76;
        onTap = () {
          _keyboardController.toggleCapsLock();
        };
        break;
      case 'BACKSPACE':
        isSpecial = true;
        width = 56;
        onTap = () {
          _keyboardController.backspace();
        };
        break;
      case 'ENTER':
        isSpecial = true;
        isWide = true;
        onTap = () {
          final success = _keyboardController.enter();
          if (!success) {
            return;
          }

          if (widget.commitOnEnterOnly) {
            widget.controller.text = _inputController.text;
            widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length,
            );
          }

          widget.onSubmitted?.call(_inputController.text);
          widget.onEnterPressed?.call();
        };
        break;
      case 'SPACE':
        isWide = true;
        width = 300;
        key = 'space';
        onTap = () {
          _keyboardController.insertSpace();
        };
        break;
      case '?123':
        isSpecial = true;
        onTap = () {
          _keyboardController.toggleNumeric();
        };
        break;
      case 'ABC':
        isSpecial = true;
        onTap = () {
          _keyboardController.switchToAlpha();
        };
        break;
      default:
        onTap = () {
          if (isDual) {
            final valueToInsert =
                (_keyboardController.isShiftActive ||
                    _keyboardController.isCapsLock)
                ? topChar
                : bottomChar;
            _keyboardController.insertText(valueToInsert);
            return;
          }
          _keyboardController.insertText(key);
        };
        break;
    }

    if (width == null && isWide) width = 120;

    Widget keyWidget;
    if (isDual) {
      keyWidget = DualKey(
        topChar: topChar,
        bottomChar: bottomChar,
        onTap: onTap,
        onLongPressKey: () {
          _keyboardController.insertText(topChar);
        },
        height: keyBodyHeight,
        alternateChars: alternates,
        onAlternateSelected: onAlternate,
        theme: theme,
      );
    } else {
      keyWidget = KeyboardKey(
        label: key,
        onTap: onTap,
        onLongPressStart: key == 'BACKSPACE' ? _startContinuousBackspace : null,
        onLongPressEnd: key == 'BACKSPACE' ? _stopContinuousBackspace : null,
        isSpecial: isSpecial,
        isActive: isActive,
        isWide: isWide,
        width: width,
        height: keyBodyHeight,
        alternateChars: alternates,
        onAlternateSelected: onAlternate,
        theme: theme,
      );
    }

    if (width == null) {
      return Expanded(child: keyWidget);
    } else {
      return SizedBox(width: width, child: keyWidget);
    }
  }
}
