import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'onscreen_keyboard_colors.dart';
import 'onscreen_keyboard_config.dart';

/// Owns [KeyboardTheme] and Material [ThemeData] for the host app and keyboards.
/// Call [updateTheme], [customizeKeyboardTheme], or [toggleTheme]; wrap your
/// [MaterialApp] / app shell with a [ListenableBuilder] on this controller so
/// scaffold colors stay in sync with [keyboardTheme.backgroundColor].
class ThemeController extends ChangeNotifier {
  bool _isDarkMode = true;

  Color _primaryColor = const Color(0xFF9C27B0);

  KeyboardTheme _keyboardTheme = KeyboardTheme.purpleCyan();

  bool get isDarkMode => _isDarkMode;

  Color get primaryColor => _primaryColor;

  KeyboardTheme get keyboardTheme => _keyboardTheme;

  ThemeController() {
    final cfg = globalOnscreenKeyboardConfig;
    if (cfg.keyboardTheme != null && cfg.replaceDefaultTheme) {
      _keyboardTheme = cfg.keyboardTheme!;
      _isDarkMode =
          cfg.keyboardTheme!.backgroundColor.computeLuminance() < 0.4;
      return;
    }

    final brightness = PlatformDispatcher.instance.platformBrightness;

    _isDarkMode = brightness == Brightness.dark;

    _keyboardTheme = _isDarkMode
        ? KeyboardTheme.darkTheme()
        : KeyboardTheme.lightTheme();
  }

  /// Sets the on-screen keyboard palette and notifies listeners.
  void updateTheme(KeyboardTheme newTheme) {
    if (identical(_keyboardTheme, newTheme)) return;
    _keyboardTheme = newTheme;
    notifyListeners();
  }

  /// Adjusts the current [KeyboardTheme] with a callback (e.g. [KeyboardTheme.copyWith]).
  void customizeKeyboardTheme(KeyboardTheme Function(KeyboardTheme current) fn) {
    _keyboardTheme = fn(_keyboardTheme);
    notifyListeners();
  }

  void toggleTheme() {
    if (globalOnscreenKeyboardConfig.lockKeyboardTheme &&
        globalOnscreenKeyboardConfig.keyboardTheme != null) {
      return;
    }

    _isDarkMode = !_isDarkMode;

    _keyboardTheme = _isDarkMode
        ? KeyboardTheme.darkTheme()
        : KeyboardTheme.lightTheme();

    notifyListeners();
  }

  /// Sets light/dark mode without changing the current [KeyboardTheme].
  void setDarkMode(bool isDark) {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
  }

  /// Applies a keyboard palette from [OnscreenKeyboardColors] and optional
  /// brightness in one call (used by host apps that own light/dark palettes).
  void applyKeyboardColors(
    OnscreenKeyboardColors colors, {
    bool? isDarkMode,
  }) {
    if (isDarkMode != null) {
      _isDarkMode = isDarkMode;
    }
    _keyboardTheme = KeyboardTheme.fromColors(colors);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get lightTheme => _generateTheme(Brightness.light);

  ThemeData get darkTheme => _generateTheme(Brightness.dark);

  ThemeData _generateTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: _keyboardTheme.backgroundColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF4A148C)
            : const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

/// Visual tokens for [CustomKeyboard], [NumericKeyboard], and draggable panels.
class KeyboardTheme {
  final Color backgroundColor;
  final Color keyBackgroundColor;
  final Color keyTextColor;
  final Color specialKeyColor;
  final Color specialKeyTextColor;
  final Color activeKeyColor;
  final Color keyPressedColor;
  final Color activeKeyTextColor;
  final Color keyBorderColor;
  final double keyBorderWidth;
  final double borderRadius;
  final double fontSize;
  final double keySpacing;
  final double keyElevation;
  final Color shadowColor;
  final Gradient primaryGradient;
  final Color previewBackgroundColor;
  final Color previewTextColor;
  final Color previewBorderColor;
  final Color chromeIconColor;

  /// Builds a full [KeyboardTheme] from [OnscreenKeyboardColors] (all colors in one place).
  factory KeyboardTheme.fromColors(OnscreenKeyboardColors colors) {
    final border = colors.keyBorder ?? colors.keyText.withValues(alpha: 0.3);
    final shadow = colors.shadow ?? Colors.black.withValues(alpha: 0.4);
    final gradientTop = colors.gradientTop ?? colors.keyBackground;
    final gradientBottom = colors.gradientBottom ?? colors.keyBackground;
    final previewText = colors.previewText ?? colors.keyText;
    final previewBackground =
        colors.previewBackground ?? colors.keyBackground;
    final previewBorder = colors.previewBorder ?? border;
    final chromeIcon = colors.chromeIcon ?? previewText;

    return KeyboardTheme(
      backgroundColor: colors.background,
      keyBackgroundColor: colors.keyBackground,
      keyTextColor: colors.keyText,
      specialKeyColor: colors.specialKeyBackground,
      specialKeyTextColor: colors.specialKeyText,
      activeKeyColor: colors.activeKey,
      keyPressedColor: colors.keyPressed ?? colors.activeKey,
      activeKeyTextColor: colors.activeKeyText ?? Colors.white,
      keyBorderColor: border,
      keyBorderWidth: colors.keyBorderWidth,
      borderRadius: colors.borderRadius,
      fontSize: colors.fontSize,
      keySpacing: colors.keySpacing,
      keyElevation: colors.keyElevation,
      shadowColor: shadow,
      primaryGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientTop, gradientBottom],
      ),
      previewBackgroundColor: previewBackground,
      previewTextColor: previewText,
      previewBorderColor: previewBorder,
      chromeIconColor: chromeIcon,
    );
  }

  const KeyboardTheme({
    required this.backgroundColor,
    required this.keyBackgroundColor,
    required this.keyTextColor,
    required this.specialKeyColor,
    required this.specialKeyTextColor,
    required this.activeKeyColor,
    required this.keyPressedColor,
    required this.activeKeyTextColor,
    required this.keyBorderColor,
    required this.keyBorderWidth,
    required this.borderRadius,
    required this.fontSize,
    required this.keySpacing,
    required this.keyElevation,
    required this.shadowColor,
    required this.primaryGradient,
    required this.previewBackgroundColor,
    required this.previewTextColor,
    required this.previewBorderColor,
    required this.chromeIconColor,
  });

  // PURPLE CYAN THEME
  factory KeyboardTheme.purpleCyan() {
    const keyBg = Color(0xFF3D0F5C);
    const keyText = Color(0xFFE0D0FF);
    const border = Color(0xFF5A3A7A);
    return KeyboardTheme(
      backgroundColor: const Color(0xFF2D004D),
      keyBackgroundColor: keyBg,
      keyTextColor: keyText,
      specialKeyColor: const Color(0xFF4A1A6B),
      specialKeyTextColor: const Color(0xFF00E5D4),
      activeKeyColor: const Color(0xFF31AC6F),
      keyPressedColor: const Color(0xFF31AC6F),
      activeKeyTextColor: Colors.white,
      keyBorderColor: border.withValues(alpha: 0.5),
      keyBorderWidth: 1,
      borderRadius: 8,
      fontSize: 16,
      keySpacing: 6,
      keyElevation: 4,
      shadowColor: Colors.black,
      primaryGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A1A6B),
          Color(0xFF2D0A4A),
        ],
      ),
      previewBackgroundColor: keyBg,
      previewTextColor: keyText,
      previewBorderColor: border.withValues(alpha: 0.5),
      chromeIconColor: keyText,
    );
  }

  // DARK THEME
  factory KeyboardTheme.darkTheme() {
    return KeyboardTheme.purpleCyan();
  }

  // LIGHT THEME
  factory KeyboardTheme.lightTheme() {
    const keyBg = Color(0xFFF3E5F5);
    const keyText = Colors.black87;
    final border = Colors.grey.withValues(alpha: 0.3);
    return KeyboardTheme(
      backgroundColor: Colors.white,
      keyBackgroundColor: keyBg,
      keyTextColor: keyText,
      specialKeyColor: const Color(0xFF9C27B0),
      specialKeyTextColor: Colors.white,
      activeKeyColor: const Color(0xFF31AC6F),
      keyPressedColor: const Color(0xFF31AC6F),
      activeKeyTextColor: Colors.white,
      keyBorderColor: border,
      keyBorderWidth: 1,
      borderRadius: 8,
      fontSize: 16,
      keySpacing: 6,
      keyElevation: 2,
      shadowColor: Colors.black12,
      primaryGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE1BEE7),
          Color(0xFFF3E5F5),
        ],
      ),
      previewBackgroundColor: keyBg,
      previewTextColor: keyText,
      previewBorderColor: border,
      chromeIconColor: keyText,
    );
  }

  KeyboardTheme copyWith({
    Color? backgroundColor,
    Color? keyBackgroundColor,
    Color? keyTextColor,
    Color? specialKeyColor,
    Color? specialKeyTextColor,
    Color? activeKeyColor,
    Color? keyPressedColor,
    Color? activeKeyTextColor,
    Color? keyBorderColor,
    double? keyBorderWidth,
    double? borderRadius,
    double? fontSize,
    double? keySpacing,
    double? keyElevation,
    Color? shadowColor,
    Gradient? primaryGradient,
    Color? previewBackgroundColor,
    Color? previewTextColor,
    Color? previewBorderColor,
    Color? chromeIconColor,
  }) {
    return KeyboardTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      keyBackgroundColor: keyBackgroundColor ?? this.keyBackgroundColor,
      keyTextColor: keyTextColor ?? this.keyTextColor,
      specialKeyColor: specialKeyColor ?? this.specialKeyColor,
      specialKeyTextColor: specialKeyTextColor ?? this.specialKeyTextColor,
      activeKeyColor: activeKeyColor ?? this.activeKeyColor,
      keyPressedColor: keyPressedColor ?? this.keyPressedColor,
      activeKeyTextColor: activeKeyTextColor ?? this.activeKeyTextColor,
      keyBorderColor: keyBorderColor ?? this.keyBorderColor,
      keyBorderWidth: keyBorderWidth ?? this.keyBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      fontSize: fontSize ?? this.fontSize,
      keySpacing: keySpacing ?? this.keySpacing,
      keyElevation: keyElevation ?? this.keyElevation,
      shadowColor: shadowColor ?? this.shadowColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      previewBackgroundColor:
          previewBackgroundColor ?? this.previewBackgroundColor,
      previewTextColor: previewTextColor ?? this.previewTextColor,
      previewBorderColor: previewBorderColor ?? this.previewBorderColor,
      chromeIconColor: chromeIconColor ?? this.chromeIconColor,
    );
  }
}
