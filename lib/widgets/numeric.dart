import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/numericKeyController.dart';
import '../core/theme_controller.dart';
import 'numerickeyboardkey.dart';

class NumericKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onEnterPressed;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onValueChanged;
  final String? Function(String)? validator;
  final bool commitOnEnterOnly;
  final double? height;

  /// Inclusive bounds for whole-number input. Shown on the keyboard and enforced
  /// before [validator] runs (range first, then custom [validator]).
  final int? minValue;
  final int? maxValue;

  /// Called when the user dismisses the keyboard without committing: after the
  /// **close** (X) runs [NumericKeyboardController.closeKeyboard]. To dismiss
  /// when the user taps outside the keyboard, wrap the keyboard and your
  /// content in a parent [TapRegion] (see package example). Optional.
  final VoidCallback? onTapOutside;

  /// When set, used instead of [ThemeController.keyboardTheme] (no GetX listen).
  final KeyboardTheme? keyboardTheme;

  const NumericKeyboard({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onEnterPressed,
    this.onSubmitted,
    this.onValueChanged,
    this.validator,
    this.commitOnEnterOnly = false,
    this.height,
    this.minValue,
    this.maxValue,
    this.onTapOutside,
    this.keyboardTheme,
  });

  @override
  State<NumericKeyboard> createState() => _NumericKeyboardState();
}

class _NumericKeyboardState extends State<NumericKeyboard> {
  late NumericKeyboardController _keyboardController;
  late TextEditingController _inputController;
  late bool _ownsInputController;

  @override
  void initState() {
    super.initState();
    _ownsInputController = widget.commitOnEnterOnly;
    _inputController = _ownsInputController
        ? TextEditingController(text: _seedText(widget.controller.text))
        : widget.controller;
    _initController();
  }

  String _seedText(String committed) {
    if (committed.isEmpty) return '0';
    return committed;
  }

  void _initController() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
      _keyboardController = Get.find<NumericKeyboardController>(tag: tag);
    } else {
      _keyboardController = NumericKeyboardController(
        textController: _inputController,
        focusNode: widget.focusNode,
        validator: _combinedValidate,
      );
      Get.put(_keyboardController, tag: tag);
    }
  }

  String? _combinedValidate(String value) {
    final rangeError = _rangeValidate(value);
    if (rangeError != null) return rangeError;
    return widget.validator?.call(value);
  }

  String? _rangeValidate(String value) {
    if (widget.minValue == null && widget.maxValue == null) return null;
    final n = int.tryParse(value);
    if (n == null) {
      return 'Enter a number';
    }
    if (widget.minValue != null && n < widget.minValue!) {
      return 'Must be >= ${widget.minValue}';
    }
    if (widget.maxValue != null && n > widget.maxValue!) {
      return 'Must be <= ${widget.maxValue}';
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant NumericKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.commitOnEnterOnly) {
      _inputController.text = _seedText(widget.controller.text);
    }
    if (widget.minValue != oldWidget.minValue ||
        widget.maxValue != oldWidget.maxValue ||
        widget.validator != oldWidget.validator) {
      final tag = widget.focusNode.hashCode.toString();
      if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
        Get.find<NumericKeyboardController>(tag: tag).validateNow();
      }
    }
  }

  @override
  void dispose() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
      Get.delete<NumericKeyboardController>(tag: tag);
    }
    if (_ownsInputController) {
      _inputController.dispose();
    }
    super.dispose();
  }

  void _reseedStagingFromCommitted() {
    _inputController.text = _seedText(widget.controller.text);
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.keyboardTheme != null) {
      return _buildWithTheme(context, widget.keyboardTheme!);
    }
    if (!Get.isRegistered<ThemeController>()) {
      return _buildWithTheme(context, KeyboardTheme.purpleCyan());
    }
    return Obx(() {
      Get.find<ThemeController>().keyboardThemeRx.value;
      return _buildWithTheme(
        context,
        Get.find<ThemeController>().keyboardTheme,
      );
    });
  }

  Widget _buildWithTheme(BuildContext context, KeyboardTheme theme) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final resolvedHeight =
        widget.height ?? media.size.height * (isLandscape ? 0.42 : 0.38);

    return Obx(() {
      return Container(
        height: resolvedHeight,
        decoration: BoxDecoration(color: theme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.fromLTRB(12, 10, 0, 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      border: const Border(
                        bottom: BorderSide(
                          color: Colors.white24,
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _inputController,
                      builder: (context, value, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                value.text,
                                style: TextStyle(
                                  color: theme.keyTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.keyTextColor,
                    ),
                    onPressed: () {
                      _keyboardController.closeKeyboard();
                      widget.onTapOutside?.call();
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: Text(
                _keyboardController.validationError ?? "",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),
            if (widget.minValue != null || widget.maxValue != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.minValue != null) ...[
                      _boundField(
                        theme,
                        'Min Value',
                        '${widget.minValue}',
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (widget.maxValue != null)
                      _boundField(
                        theme,
                        'Max Value',
                        '${widget.maxValue}',
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildDigitRow(
                              theme,
                              const ['7', '8', '9'],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _buildDigitRow(
                              theme,
                              const ['4', '5', '6'],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _buildDigitRow(
                              theme,
                              const ['1', '2', '3'],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _buildDigitKey(theme, '0'),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _decimalKey(theme),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _backSpaceKey(theme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _ctrlKey(theme),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _enterKey(theme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _boundField(KeyboardTheme theme, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.specialKeyTextColor,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: theme.keyTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _backSpaceKey(KeyboardTheme theme) {
    return NumericKey(
      theme: theme,
      onTap: () => _keyboardController.backspace(),
      isSpecial: true,
      child: Icon(
        Icons.backspace_outlined,
        color: theme.specialKeyTextColor,
        size: 20,
      ),
    );
  }

  Widget _decimalKey(KeyboardTheme theme) {
    return NumericKey(
      theme: theme,
      onTap: () => _keyboardController.insertDecimal(),
      isSpecial: true,
      child: Text(
        '.',
        style: TextStyle(
          color: theme.keyTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ctrlKey(KeyboardTheme theme) {
    return NumericKey(
      theme: theme,
      onTap: () => _keyboardController.clear(),
      isSpecial: true,
      child: Text(
        'Clear',
        style: TextStyle(
          color: theme.specialKeyTextColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _enterKey(KeyboardTheme theme) {
    return NumericKey(
      theme: theme,
      onTap: () {
        final success = _keyboardController.enter();
        if (!success) return;

        if (widget.commitOnEnterOnly) {
          widget.controller.text = _inputController.text;
          widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length,
          );
        }

        widget.onSubmitted?.call(_inputController.text);
        widget.onEnterPressed?.call();
      },
      isSpecial: true,
      child: Text(
        'Enter',
        style: TextStyle(
          color: theme.specialKeyTextColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDigitRow(KeyboardTheme theme, List<String> digits) {
    return Row(
      children: digits
          .map(
            (digit) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDigitKey(theme, digit),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDigitKey(KeyboardTheme theme, String digit) {
    return NumericKey(
      theme: theme,
      onTap: () => _keyboardController.insertDigit(digit),
      child: Text(
        digit,
        style: TextStyle(
          color: theme.keyTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
