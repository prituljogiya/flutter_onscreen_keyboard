import 'package:flutter/material.dart';

import '../core/onscreen_keyboard_input_bridge.dart';
import '../flutter_onscreen_keyboard_init.dart';
import 'custom_keyboard.dart';
import 'draggable.dart';
import 'numeric.dart';
import 'onscreen_keyboard_field_rules.dart';

/// Root-level widget that auto-attaches the on-screen keyboard to **every**
/// vanilla [TextField] / [TextFormField] in the app, without per-field or
/// per-screen wrapping.
///
/// Install once at the root via [MaterialApp.builder]:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => OnscreenKeyboardAttachment(child: child!),
///   ...
/// );
/// ```
///
/// What it does:
///
///   * Installs [OnscreenKeyboardInputControl] on Flutter's [TextInput] so
///     the system IME never shows.
///   * Publishes the shared [ThemeController] (same as [OnscreenKeyboardBinding])
///     so keyboard widgets resolve colors anywhere in the tree.
///   * Listens to [OnscreenKeyboardInputBridge] and slides a keyboard panel
///     in/out below the active screen content.
///
/// When [OnscreenKeyboardConfig.useCustomKeyboard] is false, this widget is
/// inert — the platform keyboard is used and no panel is mounted.
class OnscreenKeyboardAttachment extends StatefulWidget {
  const OnscreenKeyboardAttachment({
    super.key,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 220),
    this.useDraggableInLandscape = true,
    this.draggableWidthFactor = 0.5,
    this.draggableHeightFactor = 0.5,
    this.draggableInitialPosition = const Offset(50, 400),
    this.commitOnEnterOnly = false,
    this.onEnterPressed,
    this.onTapOutside,
    this.lockContentWhileKeyboardVisible = true,
    this.dismissOnTapOutside = false,
    this.dismissOnSystemBack = false,
  });

  final Widget child;
  final Duration transitionDuration;

  /// When true (default) the keyboard is rendered as a floating draggable
  /// panel in landscape orientation — matching the behavior of
  /// [OnscreenKeyboardHost]. In portrait it always docks to the bottom.
  final bool useDraggableInLandscape;

  /// Fraction of the screen width occupied by the draggable panel.
  final double draggableWidthFactor;

  /// Fraction of the screen height occupied by the draggable panel.
  final double draggableHeightFactor;

  /// Starting offset of the draggable panel in landscape.
  final Offset draggableInitialPosition;

  /// When true, typed characters stay in the keyboard's preview strip and
  /// only flow into the active field on Enter. When false (default for
  /// auto-attach mode) every keystroke is pushed to the field live.
  final bool commitOnEnterOnly;

  /// Called when the user taps the Enter key, after the framework's
  /// `performAction` runs.
  final VoidCallback? onEnterPressed;

  /// Called when the user dismisses the keyboard via the close (X) button.
  final VoidCallback? onTapOutside;

  /// When true (default), blocks pointer interaction with page content while
  /// the keyboard is visible so another field cannot steal focus.
  final bool lockContentWhileKeyboardVisible;

  /// When true, tapping outside the keyboard panel dismisses it. Defaults to
  /// false so dismissal happens only via the close button (kiosk-style).
  final bool dismissOnTapOutside;

  /// When true, the system back gesture/button dismisses the keyboard.
  /// Defaults to false so only the close (X) button dismisses it.
  final bool dismissOnSystemBack;

  @override
  State<OnscreenKeyboardAttachment> createState() =>
      _OnscreenKeyboardAttachmentState();
}

class _OnscreenKeyboardAttachmentState
    extends State<OnscreenKeyboardAttachment> {
  late final OnscreenKeyboardInputBridge _bridge;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    FlutterOnscreenKeyboard.ensureInitialized();
    _bridge = OnscreenKeyboardInputBridge.instance;
    _maybeInstall();
  }

  void _maybeInstall() {
    if (!useCustomOnscreenKeyboard || _installed) return;
    OnscreenKeyboardInputControl.instance.install();
    _installed = true;
  }

  @override
  void dispose() {
    if (_installed) {
      OnscreenKeyboardInputControl.instance.uninstall();
      _installed = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make sure we react to runtime flips of [useCustomOnscreenKeyboard]; the
    // bridge is a no-op when the flag is false.
    _maybeInstall();

    if (!useCustomOnscreenKeyboard) {
      return OnscreenKeyboardThemeScope(
        controller: FlutterOnscreenKeyboard.themeController,
        child: widget.child,
      );
    }

    return OnscreenKeyboardThemeScope(
      controller: FlutterOnscreenKeyboard.themeController,
      child: AnimatedBuilder(
        animation: _bridge,
        builder: (context, _) {
          return PopScope(
            canPop: !_bridge.isVisible,
            onPopInvokedWithResult: widget.dismissOnSystemBack
                ? (didPop, result) {
                    if (!didPop && _bridge.isVisible) _bridge.dismiss();
                  }
                : null,
            child: _buildShell(context),
          );
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (widget.useDraggableInLandscape && isLandscape) {
      return _buildDraggableShell();
    }
    return _buildDockedShell();
  }

  /// Landscape: float the keyboard panel as a draggable card stacked on top of
  /// the underlying screen. Matches [OnscreenKeyboardHost]'s landscape mode.
  ///
  /// The same [DraggableDynamicKeyboard] handles both alpha and numeric — when
  /// the active field's [TextInputType] is numeric the bridge flips
  /// [OnscreenKeyboardInputBridge.useNumericKeyboard] to `true` and the
  /// draggable card renders the numeric pad instead of QWERTY.
  Widget _wrapContent(Widget child) {
    if (!widget.lockContentWhileKeyboardVisible || !_bridge.isVisible) {
      return child;
    }
    return AbsorbPointer(absorbing: true, child: child);
  }

  Widget _buildDraggableShell() {
    if (!_bridge.isVisible) {
      return widget.child;
    }
    final rules =
        OnscreenKeyboardFieldRules.lookup(_bridge.focusNode);
    final maxLength = rules?.maxLength;

    return DraggableDynamicKeyboard(
      // The bridge's useNumericKeyboard flag flips based on the active
      // field's TextInputType, so the SAME draggable widget renders the
      // numeric pad for `number` / `phone` fields and QWERTY for everything
      // else. The draggable behavior is identical in both cases.
      key: ValueKey<String>(
        'auto_dk_${_bridge.useNumericKeyboard}_${_bridge.showDecimalKey}_${_bridge.integersOnly}_$maxLength',
      ),
      controller: _bridge.controller,
      focusNode: _bridge.focusNode,
      commitOnEnterOnly: widget.commitOnEnterOnly,
      useNumericKeyboard: _bridge.useNumericKeyboard,
      minLength: rules?.minLength,
      maxLength: maxLength,
      validator: rules?.validator,
      numericMinValue: rules?.minValue,
      numericMaxValue: rules?.maxValue,
      numericAllowDecimalInput:
          rules?.allowDecimalInput ?? _bridge.showDecimalKey,
      numericIntegersOnly: rules?.integersOnly ?? _bridge.integersOnly,
      numericMaxFractionDigits: rules?.maxFractionDigits,
      widthFactor: widget.draggableWidthFactor,
      heightFactor: widget.draggableHeightFactor,
      initialPosition: widget.draggableInitialPosition,
      fullWidthInLandscape: false,
      alwaysVisible: true,
      pushContent: false,
      onDismiss: _handleDismiss,
      onEnterPressed: _handleEnter,
      child: _wrapContent(widget.child),
    );
  }

  /// Portrait: dock the keyboard to the bottom and push the form content up.
  Widget _buildDockedShell() {
    final content = _wrapContent(widget.child);
    final body = Column(
      children: [
        Expanded(child: content),
        AnimatedSize(
          duration: widget.transitionDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _bridge.isVisible
              ? _buildDockedPanel()
              : const SizedBox(height: 0, width: double.infinity),
        ),
      ],
    );
    if (!widget.dismissOnTapOutside) {
      return body;
    }
    return TapRegion(
      onTapOutside: (_) => _handleDismiss(),
      child: body,
    );
  }

  Widget _buildDockedPanel() {
    final rules =
        OnscreenKeyboardFieldRules.lookup(_bridge.focusNode);
    final maxLength = rules?.maxLength;

    if (_bridge.useNumericKeyboard) {
      return RepaintBoundary(
        child: NumericKeyboard(
          key: ValueKey<String>(
            'auto_nk_${_bridge.showDecimalKey}_${_bridge.integersOnly}_$maxLength',
          ),
          controller: _bridge.controller,
          focusNode: _bridge.focusNode,
          commitOnEnterOnly: widget.commitOnEnterOnly,
          minValue: rules?.minValue,
          maxValue: rules?.maxValue,
          allowDecimalInput: rules?.allowDecimalInput ?? _bridge.showDecimalKey,
          integersOnly: rules?.integersOnly ?? _bridge.integersOnly,
          maxFractionDigits: rules?.maxFractionDigits,
          maxLength: maxLength,
          validator: rules?.validator,
          onDismiss: _handleDismiss,
          onEnterPressed: _handleEnter,
        ),
      );
    }

    return RepaintBoundary(
      child: CustomKeyboard(
        key: ValueKey<String>('auto_alpha_$maxLength'),
        controller: _bridge.controller,
        focusNode: _bridge.focusNode,
        commitOnEnterOnly: widget.commitOnEnterOnly,
        minLength: rules?.minLength,
        maxLength: maxLength,
        validator: rules?.validator,
        onDismiss: _handleDismiss,
        onEnterPressed: _handleEnter,
      ),
    );
  }

  void _handleEnter() {
    _bridge.performAction();
    widget.onEnterPressed?.call();
  }

  void _handleDismiss() {
    _bridge.dismiss();
    widget.onTapOutside?.call();
  }
}
