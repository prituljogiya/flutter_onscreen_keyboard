import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/keyboard_chrome_layout.dart';
import '../core/keyboard_theme_resolver.dart';
import '../core/numeric_range.dart';
import '../core/onscreen_keyboard_validation.dart';
import '../core/preview_strip_scroll.dart';
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

  /// Inclusive bounds (integers or decimals). Shown on the keyboard and enforced
  /// before [validator] runs (range first, then custom [validator]).
  final num? minValue;
  final num? maxValue;

  /// When false, hides the decimal (`.`) key on the pad.
  final bool allowDecimalInput;

  /// When true, only whole numbers are accepted (range min/max still applies).
  final bool integersOnly;

  /// Maximum characters in the preview (e.g. 4 for an access code).
  final int? maxLength;

  /// Called when the user taps close (X) or the host dismisses the panel.
  final VoidCallback onDismiss;

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
    this.allowDecimalInput = true,
    this.integersOnly = false,
    this.maxLength,
    required this.onDismiss,
    this.keyboardTheme,
  });

  @override
  State<NumericKeyboard> createState() => _NumericKeyboardState();
}

class _NumericKeyboardState extends State<NumericKeyboard> {
  late NumericKeyboardController _keyboardController;
  late TextEditingController _inputController;
  late bool _ownsInputController;
  late final FocusNode _previewFocusNode;
  late final ScrollController _previewScrollController;
  bool _suppressPreviewRefocus = false;
  bool _teardown = false;

  void _ensurePreviewSelectionAtEnd() {
    final text = _inputController.text;
    final selection = _inputController.selection;
    if (!selection.isValid && text.isNotEmpty) {
      _inputController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  static const TextStyle _previewTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  void _syncPreviewScroll() {
    if (_teardown || !mounted) return;
    schedulePreviewStripScroll(
      scrollController: _previewScrollController,
      textController: _inputController,
      textStyle: _previewTextStyle,
      canScroll: () => mounted && !_teardown,
    );
  }

  void _closePanel() {
    if (_teardown) return;
    _suppressPreviewRefocus = true;
    widget.onDismiss();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressPreviewRefocus = false;
    });
  }

  void _onHostFieldFocusChanged() {
    if (!widget.focusNode.hasFocus || !mounted || _suppressPreviewRefocus) {
      return;
    }
    _ensurePreviewSelectionAtEnd();
    if (_previewFocusNode.canRequestFocus) {
      _previewFocusNode.requestFocus();
    }
  }

  void _retainPreviewFocus() {
    if (!mounted || _suppressPreviewRefocus) return;
    if (!_previewFocusNode.canRequestFocus) return;
    if (!_previewFocusNode.hasFocus) {
      _previewFocusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _previewFocusNode = FocusNode(debugLabel: 'numericKeyboardPreview');
    _previewScrollController = ScrollController();
    widget.focusNode.addListener(_onHostFieldFocusChanged);
    _ownsInputController = widget.commitOnEnterOnly;
    _inputController = _ownsInputController
        ? TextEditingController(text: _seedText(widget.controller.text))
        : widget.controller;
    _inputController.addListener(_syncPreviewScroll);
    _ensurePreviewSelectionAtEnd();
    _initController();
    if (widget.focusNode.hasFocus) {
      _onHostFieldFocusChanged();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPreviewScroll();
    });
  }

  String _seedText(String committed) => committed;

  void _initController() {
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
      _keyboardController = Get.find<NumericKeyboardController>(tag: tag);
      _keyboardController.rebind(
        textController: _inputController,
        previewFocusNode: _previewFocusNode,
        validator: _combinedValidate,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        maxLength: widget.maxLength,
      );
    } else {
      _keyboardController = NumericKeyboardController(
        textController: _inputController,
        focusNode: widget.focusNode,
        previewFocusNode: _previewFocusNode,
        validator: _combinedValidate,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        maxLength: widget.maxLength,
      );
      Get.put(_keyboardController, tag: tag);
    }
  }

  void _runKeyAction(VoidCallback action) {
    if (!mounted || _teardown || !_keyboardController.isActive) return;
    action();
    _syncPreviewScroll();
    _retainPreviewFocus();
  }

  String? _combinedValidate(String value, {bool allowIncomplete = true}) {
    final rangeError = _rangeValidate(
      value,
      allowIncomplete: allowIncomplete,
    );
    if (rangeError != null) return rangeError;
    return widget.validator?.call(value);
  }

  String? _rangeValidate(String value, {bool allowIncomplete = true}) {
    return NumericRange.validate(
      value,
      min: widget.minValue,
      max: widget.maxValue,
      integersOnly: widget.integersOnly,
      allowIncomplete: allowIncomplete,
    );
  }

  String _commitText(String staging) {
    return NumericRange.commitText(
      staging,
      integersOnly: widget.integersOnly,
    );
  }

  @override
  void didUpdateWidget(covariant NumericKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onHostFieldFocusChanged);
      widget.focusNode.addListener(_onHostFieldFocusChanged);
      releaseOnscreenKeyboardControllers(oldWidget.focusNode);
      _initController();
      _keyboardController.clearValidation();
      if (widget.commitOnEnterOnly) {
        _reseedStagingFromCommitted();
      }
      if (widget.focusNode.hasFocus) {
        _onHostFieldFocusChanged();
      }
    }
    if (widget.controller != oldWidget.controller && widget.commitOnEnterOnly) {
      _keyboardController.clearValidation();
      _reseedStagingFromCommitted();
    }
    if (widget.allowDecimalInput != oldWidget.allowDecimalInput ||
        widget.integersOnly != oldWidget.integersOnly ||
        widget.maxLength != oldWidget.maxLength ||
        widget.minValue != oldWidget.minValue ||
        widget.maxValue != oldWidget.maxValue) {
      _keyboardController.rebind(
        textController: _inputController,
        previewFocusNode: _previewFocusNode,
        validator: _combinedValidate,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        maxLength: widget.maxLength,
      );
      setState(() {});
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
    _teardown = true;
    widget.focusNode.removeListener(_onHostFieldFocusChanged);
    _inputController.removeListener(_syncPreviewScroll);
    final tag = widget.focusNode.hashCode.toString();
    if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
      Get.delete<NumericKeyboardController>(tag: tag);
    }
    _previewScrollController.dispose();
    _previewFocusNode.dispose();
    if (_ownsInputController) {
      _inputController.dispose();
    }
    super.dispose();
  }

  void _reseedStagingFromCommitted() {
    final text = _seedText(widget.controller.text);
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
    _syncPreviewScroll();
  }

  @override
  Widget build(BuildContext context) {
    return buildKeyboardWithResolvedTheme(
      widgetOverride: widget.keyboardTheme,
      builder: (theme) => _buildWithTheme(context, theme),
    );
  }

  Widget _buildWithTheme(BuildContext context, KeyboardTheme theme) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final hasBounds = widget.minValue != null || widget.maxValue != null;

    return Obx(() {
      final error = _keyboardController.validationErrorRx.value;
      final errorText = error != null && error.trim().isNotEmpty
          ? error.trim()
          : null;
      final showError = errorText != null;
      final showBounds = hasBounds;

      final keysHeight = MediaQuery.sizeOf(context).height *
          KeyboardChromeLayout.numericKeysFraction(isLandscape);
      final panelHeight = KeyboardChromeLayout.numericPanelHeight(
        context: context,
        isLandscape: isLandscape,
        showError: showError,
        showBounds: showBounds,
        overrideHeight: widget.height,
      );

      return Container(
        height: panelHeight,
        decoration: BoxDecoration(color: theme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildPreviewStrip(theme),
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
            if(widget.minValue != null && widget.maxValue != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _boundField(
                      theme,
                      'Min',
                      '${widget.minValue  ?? ""}',
                    ),
                    _boundField(
                      theme,
                      'Max ',
                      '${widget.maxValue ?? ""}',
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
                                  flex: widget.allowDecimalInput ? 1 : 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _buildDigitKey(theme, '0'),
                                  ),
                                ),
                                if (widget.allowDecimalInput)
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

  Widget _buildPreviewStrip(KeyboardTheme theme) {
    final caretColor = theme.keyTextColor;

    return Row(
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
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: caretColor,
                  selectionColor: Colors.white24,
                  selectionHandleColor: caretColor,
                ),
              ),
              child: TextField(
                key: const ValueKey<String>('numericKeyboardPreview'),
                controller: _inputController,
                focusNode: _previewFocusNode,
                scrollController: _previewScrollController,
                scrollPhysics: const ClampingScrollPhysics(),
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
                  color: theme.keyTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _closePanel(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closePanel,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.keyTextColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBoundsRow(KeyboardTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 4),
      child: Row(
        children: [
          if (widget.minValue != null)
            _boundField(
              theme,
              'Min Value',
              NumericRange.formatBound(widget.minValue!),
            ),
          if (widget.minValue != null && widget.maxValue != null)
            const SizedBox(width: 16),
          if (widget.maxValue != null)
            _boundField(
              theme,
              'Max Value',
              NumericRange.formatBound(widget.maxValue!),
            ),
        ],
      ),
    );
  }

  Widget _boundField(KeyboardTheme theme, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
      onTap: () => _runKeyAction(_keyboardController.backspace),
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
      onTap: () => _runKeyAction(() {
        _keyboardController.insertDecimal();
      }),
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
      onTap: () => _runKeyAction(_keyboardController.clear),
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
        _runKeyAction(() {
          final success = _keyboardController.enter(
            strictValidator: (value) =>
                _combinedValidate(value, allowIncomplete: false),
          );
          if (!success) {
            _retainPreviewFocus();
            return;
          }

          if (widget.commitOnEnterOnly) {
            final committed = _commitText(_inputController.text);
            widget.controller.text = committed;
            widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length,
            );
          }

          widget.onSubmitted?.call(_commitText(_inputController.text));
          widget.onEnterPressed?.call();
        });
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
      onTap: () => _runKeyAction(() => _keyboardController.insertDigit(digit)),
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
