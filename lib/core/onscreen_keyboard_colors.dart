import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Put every keyboard color in one class, then pass to the plugin.
///
/// ```dart
/// class AppKeyboardTheme {
///   AppKeyboardTheme._();
///
///   static const colors = OnscreenKeyboardColors(
///     background: Color(0xFF1E1E2C),
///     keyBackground: Color(0xFF2A2A3D),
///     keyText: Color(0xFFFFFFFF),
///     specialKeyBackground: Color(0xFF3D3D56),
///     specialKeyText: Color(0xFF00E5D4),
///     activeKey: Color(0xFF5C6BC0),
///   );
/// }
///
/// void main() {
///   FlutterOnscreenKeyboard.configure(
///     OnscreenKeyboardConfig.withColors(colors: AppKeyboardTheme.colors),
///   );
/// }
/// ```
class OnscreenKeyboardColors {
  const OnscreenKeyboardColors({
    required this.background,
    required this.keyBackground,
    required this.keyText,
    required this.specialKeyBackground,
    required this.specialKeyText,
    required this.activeKey,
    this.keyPressed,
    this.activeKeyText,
    this.keyBorder,
    this.shadow,
    this.gradientTop,
    this.gradientBottom,
    this.keyBorderWidth = 1,
    this.borderRadius = 8,
    this.fontSize = 16,
    this.keySpacing = 6,
    this.keyElevation = 4,
  });

  /// Keyboard panel background.
  final Color background;

  /// Standard letter / number keys.
  final Color keyBackground;

  /// Text and icons on standard keys.
  final Color keyText;

  /// Shift, Caps, Enter, backspace row keys.
  final Color specialKeyBackground;

  /// Labels on special keys and preview caret.
  final Color specialKeyText;

  /// Shift / Caps lock active background.
  final Color activeKey;

  /// Background while a key is held down. Defaults to [activeKey] if omitted.
  final Color? keyPressed;

  /// Text and icons on pressed / active keys. Defaults to white if omitted.
  final Color? activeKeyText;

  /// Key outline. Defaults to [keyText] at 30% opacity if omitted.
  final Color? keyBorder;

  /// Key shadow. Defaults to black at 40% opacity if omitted.
  final Color? shadow;

  /// Top of letter-key gradient. Defaults to [keyBackground] if omitted.
  final Color? gradientTop;

  /// Bottom of letter-key gradient. Defaults to [keyBackground] if omitted.
  final Color? gradientBottom;

  final double keyBorderWidth;
  final double borderRadius;
  final double fontSize;
  final double keySpacing;
  final double keyElevation;

  /// Builds the [KeyboardTheme] used by all keyboard widgets.
  KeyboardTheme toTheme() => KeyboardTheme.fromColors(this);
}
