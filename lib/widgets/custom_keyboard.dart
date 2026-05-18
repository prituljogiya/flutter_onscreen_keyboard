import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide KeyboardKey;
import 'package:flutter_onscreen_keyboard/core/keyboard_controller.dart';
import 'package:flutter_onscreen_keyboard/widgets/keyboardkey.dart';
import 'package:get/get.dart';
import '../core/keyboard_theme_resolver.dart';
import '../core/theme_controller.dart';
import 'duelKey.dart';

class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onEnterPressed;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String)? validator;
  final bool commitOnEnterOnly;
  final double? height;

  /// Same value as a host [TextField.maxLength], if any. Stops further typing
  /// on the custom keyboard once the (preview) text reaches this length.
  final int? maxLength;

  /// Minimum preview length before Enter commits (shown on the keyboard panel).
  final int? minLength;

  /// Called when the user dismisses the keyboard without committing: after
  /// [focusNode.unfocus] on outside tap (when the host wraps the keyboard in a
  /// parent [TapRegion]), or immediately after the preview **close** (X) runs
  /// [KeyboardController.closeKeyboard]. Optional.
  final VoidCallback? onTapOutside;

  /// When set, used instead of [ThemeController.keyboardTheme] (no GetX listen).
  final KeyboardTheme? keyboardTheme;

  const CustomKeyboard({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onEnterPressed,
    this.onSubmitted,
    this.validator,
    this.commitOnEnterOnly = false,
    this.height,
    this.maxLength,
    this.minLength,
    this.onTapOutside,
    this.keyboardTheme,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  late KeyboardController _keyboardController;
  late TextEditingController _inputController;
  late bool _ownsInputController;
  late final FocusNode _previewFocusNode;
  /// Avoid stealing focus from the preview strip when closing the keyboard.
  late final FocusNode _closeButtonFocusNode;
  /// Skips [ _schedulePreviewCaretRefocus ] while closing so we do not refocus.
  bool _suppressPreviewRefocus = false;
  bool _teardown = false;
  Timer? _backspaceTimer;

  void _ensurePreviewSelectionAtEnd() {
    final text = _inputController.text;
    final selection = _inputController.selection;
    if (!selection.isValid && text.isNotEmpty) {
      _inputController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void _onHostFieldFocusChanged() {
    if (!widget.focusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensurePreviewSelectionAtEnd();
      _previewFocusNode.requestFocus();
    });
  }

  void _retainPreviewFocus() {
    if (!mounted || _suppressPreviewRefocus) return;
    if (!_previewFocusNode.canRequestFocus) return;
    if (!_previewFocusNode.hasFocus) {
      _previewFocusNode.requestFocus();
    }
  }

  void _runWithKeyFlash(
    String id,
    VoidCallback action, {
    bool refocusPreview = true,
  }) {
    if (!mounted || _teardown || !_keyboardController.isActive) return;
    if (refocusPreview) {
      _retainPreviewFocus();
    }
    _keyboardController.flashKey(id);
    action();
    if (refocusPreview) {
      _retainPreviewFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _previewFocusNode = FocusNode(debugLabel: 'keyboardPreview');
    _closeButtonFocusNode = FocusNode(
      canRequestFocus: false,
      skipTraversal: true,
      debugLabel: 'keyboardClose',
    );
    widget.focusNode.addListener(_onHostFieldFocusChanged);
    _ownsInputController = widget.commitOnEnterOnly;
    _inputController = _ownsInputController
        ? TextEditingController(text: widget.controller.text)
        : widget.controller;
    _ensurePreviewSelectionAtEnd();
    _initController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.focusNode.hasFocus) {
        _onHostFieldFocusChanged();
      }
    });
  }

  void _initController() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<KeyboardController>(tag: tag)) {
      _keyboardController = Get.find<KeyboardController>(tag: tag);
      _keyboardController.rebind(
        textController: _inputController,
        previewFocusNode: _previewFocusNode,
        validator: widget.validator,
        maxLength: widget.maxLength,
        minLength: widget.minLength,
      );
    } else {
      _keyboardController = KeyboardController(
        textController: _inputController,
        focusNode: widget.focusNode,
        previewFocusNode: _previewFocusNode,
        validator: widget.validator,
        maxLength: widget.maxLength,
        minLength: widget.minLength,
      );
      Get.put(_keyboardController, tag: tag);
    }
    _keyboardController.validateNow();
  }

  @override
  void didUpdateWidget(covariant CustomKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onHostFieldFocusChanged);
      widget.focusNode.addListener(_onHostFieldFocusChanged);
    }
    if (widget.controller != oldWidget.controller && widget.commitOnEnterOnly) {
      _inputController.text = widget.controller.text;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    }
    if (widget.maxLength != oldWidget.maxLength) {
      _keyboardController.maxLength = widget.maxLength;
    }
    if (widget.minLength != oldWidget.minLength ||
        widget.maxLength != oldWidget.maxLength ||
        widget.validator != oldWidget.validator) {
      _keyboardController.minLength = widget.minLength;
      _keyboardController.validateNow();
    }
  }

  @override
  void dispose() {
    _teardown = true;
    widget.focusNode.removeListener(_onHostFieldFocusChanged);
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<KeyboardController>(tag: tag)) {
      Get.delete<KeyboardController>(tag: tag);
    }
    _stopContinuousBackspace();
    _closeButtonFocusNode.dispose();
    _previewFocusNode.dispose();
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
    return buildKeyboardWithResolvedTheme(
      widgetOverride: widget.keyboardTheme,
      builder: (theme) => _buildKeyboardShell(context, theme),
    );
  }

  Widget _buildKeyboardShell(BuildContext context, KeyboardTheme theme) {
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final isLandscape = media.orientation == Orientation.landscape;
    final keyboardHeight =
        widget.height ?? screenSize.height * (isLandscape ? 0.58 : 0.45);
    final caretColor = theme.specialKeyTextColor;

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
      child: Column(
        children: [
          _buildPreviewStrip(
            isLandscape: isLandscape,
            caretColor: caretColor,
          ),
          Obx(() {
            final err = _keyboardController.validationError;
            if (err == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  err,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
          if (widget.minLength != null || widget.maxLength != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 8, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (widget.minLength != null)
                    _lengthBoundField(
                      theme,
                      'Min Length',
                      '${widget.minLength}',
                    ),
                  if (widget.maxLength != null)
                    _lengthBoundField(
                      theme,
                      'Max Length',
                      '${widget.maxLength}',
                    ),
                ],
              ),
            ),
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _retainPreviewFocus(),
              child: Obx(() {
              final layout = _keyboardController.currentLayout;
              final flashKeyId = _keyboardController.flashKeyRx.value;
              // Repaint Shift/Caps when modifiers change (not only on layout swap).
              _keyboardController.isShiftActiveRx.value;
              _keyboardController.isCapsLockRx.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = isLandscape ? 3.0 : 4.0;
                  final keyVertInset = theme.keySpacing;
                  const layoutSafety = 2.0;
                  final availableForRows =
                      (constraints.maxHeight - layoutSafety)
                          .clamp(0.0, double.infinity);

                  final rowCount = layout.length;
                  final maxPerRow = rowCount > 0
                      ? availableForRows / rowCount
                      : availableForRows;

                  final maxRowCap = isLandscape ? 44.0 : 56.0;
                  final rowHeight =
                      maxPerRow > maxRowCap ? maxRowCap : maxPerRow;

                  final keyBodyHeight = (rowHeight - keyVertInset).clamp(
                    0.0,
                    rowHeight,
                  );

                  return _buildAlphanumericKeyboard(
                    layout,
                    theme,
                    rowHeight: rowHeight,
                    keyBodyHeight: keyBodyHeight,
                    horizontalPadding: horizontalPadding,
                    flashKeyId: flashKeyId,
                  );
                },
              );
            }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lengthBoundField(KeyboardTheme theme, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.specialKeyTextColor,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: theme.keyTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStrip({
    required bool isLandscape,
    required Color caretColor,
  }) {
    final previewHeight = isLandscape ? 38.0 : 48.0;
    final previewMargin = isLandscape ? 6.0 : 8.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: previewHeight,
            margin: EdgeInsets.all(previewMargin),
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 10 : 12,
            ),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              border: const Border(
                bottom: BorderSide(
                  color: Colors.white24,
                  width: 1.2,
                ),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: caretColor,
                  selectionColor: Colors.white24,
                  selectionHandleColor: caretColor,
                ),
              ),
              child: TextField(
                key: const ValueKey<String>('customKeyboardPreview'),
                controller: _inputController,
                focusNode: _previewFocusNode,
                keyboardType: TextInputType.none,
                textInputAction: TextInputAction.none,
                enableSuggestions: false,
                autocorrect: false,
                cursorColor: caretColor,
                cursorWidth: 2.5,
                showCursor: true,
                readOnly: true,
                enableInteractiveSelection: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLandscape ? 16 : 18,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            focusNode: _closeButtonFocusNode,
            icon: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () {
              _suppressPreviewRefocus = true;
              _keyboardController.closeKeyboard();
              widget.onTapOutside?.call();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _suppressPreviewRefocus = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlphanumericKeyboard(
      List<List<String>> layout,
      KeyboardTheme theme, {
        required double rowHeight,
        required double keyBodyHeight,
        required double horizontalPadding,
        required String? flashKeyId,
      }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: layout.map((row) {
        return SizedBox(
          height: rowHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: row.map((key) {
                return _buildKey(
                  key,
                  theme,
                  row.length,
                  flashKeyId: flashKeyId,
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
        required String? flashKeyId,
        required double rowHeight,
        required double keyBodyHeight,
      }) {
    final layoutCell = key;
    bool isSpecial = false;
    bool isActive = false;
    bool isSubActive = false;
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
          _runWithKeyFlash(layoutCell, _keyboardController.toggleShift);
        };
        break;
      case 'CAPS':
        isSpecial = true;
        isActive = _keyboardController.isCapsLock;
        width = 76;
        onTap = () {
          _runWithKeyFlash(layoutCell, _keyboardController.onCapsKeyPressed);
        };
        break;
      case 'BACKSPACE':
        isSpecial = true;
        width = 56;
        onTap = () {
          _runWithKeyFlash(layoutCell, _keyboardController.backspace);
        };
        break;
      case 'ENTER':
        isSpecial = true;
        isWide = false;
        width = 240;
        onTap = () {
          _runWithKeyFlash(
            layoutCell,
            () {
              final success = _keyboardController.enter();
              if (!success) {
                _retainPreviewFocus();
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
            },
            refocusPreview: false,
          );
        };
        break;
      case 'SPACE':
        isWide = true;
        width = 512;
        key = 'space';
        onTap = () {
          _runWithKeyFlash(layoutCell, _keyboardController.insertSpace);
        };
        break;
      case '?123':
        isSpecial = true;
        onTap = () {
          _runWithKeyFlash(layoutCell, _keyboardController.toggleNumeric);
        };
        break;
      case 'ABC':
        isSpecial = true;
        onTap = () {
          _runWithKeyFlash(layoutCell, _keyboardController.switchToAlpha);
        };
        break;
      case 'LEFT ARROW':
        isSpecial = true;
        onTap = () {
          _runWithKeyFlash(layoutCell, () => _keyboardController.moveCursor(-1));
        };
        break;
      case 'RIGHT ARROW':
        isSpecial = true;
        onTap = () {
          _runWithKeyFlash(layoutCell, () => _keyboardController.moveCursor(1));
        };
        break;
      default:
        onTap = () {
          _runWithKeyFlash(layoutCell, () {
            if (isDual) {
              final valueToInsert = _keyboardController.useTopCharacterOnDualKey
                  ? topChar
                  : bottomChar;
              _keyboardController.insertText(valueToInsert);
              return;
            }
            _keyboardController.insertText(key);
          });
        };
        break;
    }

    if (width == null && isWide) width = 300;

    Widget keyWidget;
    if (isDual) {
      keyWidget = DualKey(
        topChar: topChar,
        bottomChar: bottomChar,
        onTap: onTap,
        onLongPressKey: () {
          _runWithKeyFlash(layoutCell, () {
            _keyboardController.insertText(topChar);
          });
        },
        height: keyBodyHeight,
        alternateChars: alternates,
        onAlternateSelected: onAlternate,
        theme: theme,
        primaryIsTop: _keyboardController.useTopCharacterOnDualKey,
        isFlashHighlight: flashKeyId == layoutCell,
      );
    } else {
      keyWidget = KeyboardKey(
        label: key,
        onTap: onTap,
        onLongPressStart: key == 'BACKSPACE' ? _startContinuousBackspace : null,
        onLongPressEnd: key == 'BACKSPACE' ? _stopContinuousBackspace : null,
        isSpecial: isSpecial,
        isActive: isActive,
        isSubActive: isSubActive,
        isFlashHighlight: flashKeyId == layoutCell,
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
