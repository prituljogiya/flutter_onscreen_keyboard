import 'package:flutter/material.dart';

import '../core/keyboard_chrome_layout.dart';
import '../core/keyboard_theme_resolver.dart';
import '../flutter_onscreen_keyboard_init.dart';
import '../core/numeric_range.dart';
import '../core/preview_strip_scroll.dart';
import '../core/numeric_keyboard_controller.dart';
import '../core/theme_controller.dart';
import 'numeric_keyboard_key.dart';

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

  /// Hard cap on digits after `.`. When null, the cap is inferred from
  /// [minValue] / [maxValue] (if set). Set explicitly to limit fractional
  /// length on decimal fields that have no min/max bounds.
  final int? maxFractionDigits;

  /// Called when the user taps close (X) or the host dismisses the panel.
  final VoidCallback onDismiss;

  /// When set, used instead of [ThemeController.keyboardTheme] (skips listener).
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
    this.maxFractionDigits,
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
  KeyboardTheme? _cachedTheme;
  bool _previewScrollScheduled = false;

  void _ensurePreviewSelectionAtEnd() {
    final text = _inputController.text;
    final selection = _inputController.selection;
    if (!selection.isValid && text.isNotEmpty) {
      _inputController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  TextStyle _previewTextStyle(KeyboardTheme theme) {
    return TextStyle(
      color: theme.previewTextColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }

  /// Called from [TextEditingController] listeners — must not touch [context].
  void _syncPreviewScroll() {
    if (_teardown || !mounted || _previewScrollScheduled) return;
    _previewScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previewScrollScheduled = false;
      if (_teardown || !mounted) return;
      final theme = widget.keyboardTheme ??
          _cachedTheme ??
          FlutterOnscreenKeyboard.themeController.keyboardTheme;
      schedulePreviewStripScroll(
        scrollController: _previewScrollController,
        textController: _inputController,
        textStyle: _previewTextStyle(theme),
        canScroll: () => mounted && !_teardown,
      );
    });
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
    if (!mounted || _suppressPreviewRefocus) return;
    if (!widget.focusNode.hasFocus) return;
    _ensurePreviewSelectionAtEnd();
    if (_previewFocusNode.canRequestFocus) {
      _previewFocusNode.requestFocus();
    }
  }

  /// Take preview focus on mount so typing works even when the host field is
  /// never focused (the host's [OnscreenKeyboardHost] no longer focuses fields
  /// in order to avoid [TextField]'s auto-scroll-to-caret jump).
  void _grabPreviewFocus() {
    if (!mounted || _suppressPreviewRefocus) return;
    _ensurePreviewSelectionAtEnd();
    if (_previewFocusNode.canRequestFocus && !_previewFocusNode.hasFocus) {
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
    _grabPreviewFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPreviewScroll();
    });
  }

  String _seedText(String committed) => committed;

  void _initController() {
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
      maxFractionDigits: widget.maxFractionDigits,
    );
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
    // While the user is still typing (allowIncomplete=true) we intentionally
    // do NOT enforce [minValue] — the user is mid-typing and is on their way
    // to a valid value (e.g. typing "5" → "55" → "550" in a 10-500 field).
    // Showing "Must be >= 10" the moment they press the first digit is
    // annoying and unfixable for them until they type another digit. The
    // strict Enter path passes [allowIncomplete] = false, at which point the
    // full range check (including min) runs.
    return NumericRange.validate(
      value,
      min: allowIncomplete ? null : widget.minValue,
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
      _keyboardController.dispose();
      _initController();
      if (widget.commitOnEnterOnly) {
        _reseedStagingFromCommitted();
      }
      _grabPreviewFocus();
    }
    if (widget.controller != oldWidget.controller && widget.commitOnEnterOnly) {
      _keyboardController.clearValidation();
      _reseedStagingFromCommitted();
    }
    if (widget.allowDecimalInput != oldWidget.allowDecimalInput ||
        widget.integersOnly != oldWidget.integersOnly ||
        widget.maxLength != oldWidget.maxLength ||
        widget.minValue != oldWidget.minValue ||
        widget.maxValue != oldWidget.maxValue ||
        widget.maxFractionDigits != oldWidget.maxFractionDigits) {
      _keyboardController.rebind(
        textController: _inputController,
        previewFocusNode: _previewFocusNode,
        validator: _combinedValidate,
        allowDecimalInput: widget.allowDecimalInput,
        integersOnly: widget.integersOnly,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        maxLength: widget.maxLength,
        maxFractionDigits: widget.maxFractionDigits,
      );
      setState(() {});
    }
    if (widget.minValue != oldWidget.minValue ||
        widget.maxValue != oldWidget.maxValue ||
        widget.validator != oldWidget.validator) {
      _keyboardController.validateNow();
    }
  }

  @override
  void dispose() {
    _teardown = true;
    widget.focusNode.removeListener(_onHostFieldFocusChanged);
    _inputController.removeListener(_syncPreviewScroll);
    _keyboardController.dispose();
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
      context: context,
      builder: (theme) {
        _cachedTheme = theme;
        return _buildWithTheme(context, theme);
      },
    );
  }

  Widget _buildWithTheme(BuildContext context, KeyboardTheme theme) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final hasBounds = widget.minValue != null || widget.maxValue != null;

    return ListenableBuilder(
      listenable: _keyboardController,
      builder: (context, _) {
        final error = _keyboardController.validationError;
        final errorText = error != null && error.trim().isNotEmpty
            ? error.trim()
            : null;
        final showError = errorText != null;
        final showBounds = hasBounds;

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
    final caretColor = theme.specialKeyTextColor;
    final selectionTint =
        theme.previewTextColor.withValues(alpha: 0.25);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            margin: const EdgeInsets.fromLTRB(12, 10, 0, 3),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: theme.previewBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.previewBorderColor,
                  width: 1.2,
                ),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: caretColor,
                    selectionColor: selectionTint,
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
                style: _previewTextStyle(theme),
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
                  color: theme.chromeIconColor,
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
