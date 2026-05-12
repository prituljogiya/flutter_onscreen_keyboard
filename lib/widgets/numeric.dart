import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/numericKeyController.dart';
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
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final resolvedHeight =
        widget.height ?? media.size.height * (isLandscape ? 0.42 : 0.38);

    return Obx(() {
      return Container(
        height: resolvedHeight,
        decoration: const BoxDecoration(color: Color(0xFF2D004D)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display area - full width
            Container(
              height: isLandscape ? 60 : 72,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(0),
                border: Border.all(color: Colors.white24),
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _inputController,
                builder: (context, value, _) {
                  return Text(
                    value.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 28 : 32,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            // Validation error
            if (_keyboardController.validationError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                child: Text(
                  _keyboardController.validationError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            // Main content: keypad + min/max side panel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left side: Keypad
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildDigitRow(const ['1', '2', '3']),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _buildDigitRow(const ['4', '5', '6']),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _buildDigitRow(const ['7', '8', '9']),
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
                                    child: _clearKey(),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _buildDigitKey('0'),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _decimalKey(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _enterKey()),
                                const SizedBox(width: 8),
                                Expanded(child: _cancelKey()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right side: Min/Max values (only when bounds are set)
                    if (widget.minValue != null || widget.maxValue != null)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.minValue != null) ...[
                                _boundField('Min Value', '${widget.minValue}'),
                                const SizedBox(height: 4),
                              ],
                              if (widget.maxValue != null)
                                _boundField('Max Value', '${widget.maxValue}'),
                            ],
                          ),
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

  Widget _boundField(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00E5D4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clearKey() {
    return NumericKey(
      onTap: () => _keyboardController.clear(),
      isSpecial: true,
      child: const Text(
        'C',
        style: TextStyle(
          color: Color(0xFFE0D0FF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _decimalKey() {
    return NumericKey(
      onTap: () => _keyboardController.insertDecimal(),
      isSpecial: true,
      child: const Text(
        '.',
        style: TextStyle(
          color: Color(0xFFE0D0FF),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _enterKey() {
    return NumericKey(
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
      child: const Icon(
        Icons.keyboard_return,
        color: Color(0xFF00E5D4),
        size: 24,
      ),
    );
  }

  Widget _cancelKey() {
    return NumericKey(
      onTap: () {
        if (widget.commitOnEnterOnly) {
          _reseedStagingFromCommitted();
        } else {
          _keyboardController.cancel();
        }
        widget.onValueChanged?.call(_inputController.text);
      },
      isSpecial: true,
      child: const Text(
        'Cancel',
        style: TextStyle(
          color: Color(0xFF00E5D4),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDigitRow(List<String> digits) {
    return Row(
      children: digits
          .map(
            (digit) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDigitKey(digit),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDigitKey(String digit) {
    return NumericKey(
      onTap: () => _keyboardController.insertDigit(digit),
      child: Text(
        digit,
        style: const TextStyle(
          color: Color(0xFFE0D0FF),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
