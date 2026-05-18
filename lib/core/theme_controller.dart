import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'onscreen_keyboard_colors.dart';
import 'onscreen_keyboard_config.dart';

/// Owns [KeyboardTheme] and Material [ThemeData] for the host app and keyboards.
/// Call [updateTheme], [customizeKeyboardTheme], or [toggleTheme]; wrap
/// [GetMaterialApp] with [GetBuilder]<[ThemeController]> so scaffold colors stay
/// in sync with [keyboardTheme.backgroundColor].
class ThemeController extends GetxController {
  final RxBool _isDarkMode = true.obs;

  final Rx<Color> _primaryColor = const Color(0xFF9C27B0).obs;

  final Rx<KeyboardTheme> _keyboardTheme = KeyboardTheme.purpleCyan().obs;

  bool get isDarkMode => _isDarkMode.value;

  Color get primaryColor => _primaryColor.value;

  RxBool get isDarkModeRx => _isDarkMode;

  KeyboardTheme get keyboardTheme => _keyboardTheme.value;

  Rx<KeyboardTheme> get keyboardThemeRx => _keyboardTheme;

  ThemeController() {
    final cfg = globalOnscreenKeyboardConfig;
    if (cfg.keyboardTheme != null && cfg.replaceDefaultTheme) {
      _keyboardTheme.value = cfg.keyboardTheme!;
      _isDarkMode.value =
          cfg.keyboardTheme!.backgroundColor.computeLuminance() < 0.4;
      return;
    }

    final brightness = PlatformDispatcher.instance.platformBrightness;

    _isDarkMode.value = brightness == Brightness.dark;

    _keyboardTheme.value = _isDarkMode.value
        ? KeyboardTheme.darkTheme()
        : KeyboardTheme.lightTheme();
  }

  /// Sets the on-screen keyboard palette and rebuilds [GetBuilder]/listeners.
  void updateTheme(KeyboardTheme newTheme) {
    _keyboardTheme.value = newTheme;
    update();
  }

  /// Adjusts the current [KeyboardTheme] with a callback (e.g. [KeyboardTheme.copyWith]).
  void customizeKeyboardTheme(KeyboardTheme Function(KeyboardTheme current) fn) {
    _keyboardTheme.value = fn(_keyboardTheme.value);
    update();
  }

  void toggleTheme() {
    if (globalOnscreenKeyboardConfig.lockKeyboardTheme &&
        globalOnscreenKeyboardConfig.keyboardTheme != null) {
      return;
    }

    _isDarkMode.value = !_isDarkMode.value;

    _keyboardTheme.value = _isDarkMode.value
        ? KeyboardTheme.darkTheme()
        : KeyboardTheme.lightTheme();

    update();
  }

  void setPrimaryColor(Color color) {
    _primaryColor.value = color;
    update();
  }

  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  ThemeData get lightTheme => _generateTheme(Brightness.light);

  ThemeData get darkTheme => _generateTheme(Brightness.dark);

  ThemeData _generateTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor.value,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: _keyboardTheme.value.backgroundColor,
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
  final Color keyBorderColor;
  final double keyBorderWidth;
  final double borderRadius;
  final double fontSize;
  final double keySpacing;
  final double keyElevation;
  final Color shadowColor;
  final Gradient primaryGradient;

  /// Builds a full [KeyboardTheme] from [OnscreenKeyboardColors] (all colors in one place).
  factory KeyboardTheme.fromColors(OnscreenKeyboardColors colors) {
    final border = colors.keyBorder ?? colors.keyText.withValues(alpha: 0.3);
    final shadow = colors.shadow ?? Colors.black.withValues(alpha: 0.4);
    final gradientTop = colors.gradientTop ?? colors.keyBackground;
    final gradientBottom = colors.gradientBottom ?? colors.keyBackground;

    return KeyboardTheme(
      backgroundColor: colors.background,
      keyBackgroundColor: colors.keyBackground,
      keyTextColor: colors.keyText,
      specialKeyColor: colors.specialKeyBackground,
      specialKeyTextColor: colors.specialKeyText,
      activeKeyColor: colors.activeKey,
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
    );
  }

  const KeyboardTheme({
    required this.backgroundColor,
    required this.keyBackgroundColor,
    required this.keyTextColor,
    required this.specialKeyColor,
    required this.specialKeyTextColor,
    required this.activeKeyColor,
    required this.keyBorderColor,
    required this.keyBorderWidth,
    required this.borderRadius,
    required this.fontSize,
    required this.keySpacing,
    required this.keyElevation,
    required this.shadowColor,
    required this.primaryGradient,
  });

  // PURPLE CYAN THEME
  factory KeyboardTheme.purpleCyan() {
    return KeyboardTheme(
      backgroundColor: const Color(0xFF2D004D),
      keyBackgroundColor: const Color(0xFF3D0F5C),
      keyTextColor: const Color(0xFFE0D0FF),
      specialKeyColor: const Color(0xFF4A1A6B),
      specialKeyTextColor: const Color(0xFF00E5D4),
      activeKeyColor: const Color(0xFF4A1A6B),
      keyBorderColor: const Color(0xFF5A3A7A).withOpacity(0.5),
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
    );
  }

  // DARK THEME
  factory KeyboardTheme.darkTheme() {
    return KeyboardTheme.purpleCyan();
  }

  // LIGHT THEME
  factory KeyboardTheme.lightTheme() {
    return KeyboardTheme(
      backgroundColor: Colors.white,
      keyBackgroundColor: const Color(0xFFF3E5F5),
      keyTextColor: Colors.black87,
      specialKeyColor: const Color(0xFF9C27B0),
      specialKeyTextColor: Colors.white,
      activeKeyColor: const Color(0xFF00BCD4),
      keyBorderColor: Colors.grey.withOpacity(0.3),
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
    );
  }

  KeyboardTheme copyWith({
    Color? backgroundColor,
    Color? keyBackgroundColor,
    Color? keyTextColor,
    Color? specialKeyColor,
    Color? specialKeyTextColor,
    Color? activeKeyColor,
    Color? keyBorderColor,
    double? keyBorderWidth,
    double? borderRadius,
    double? fontSize,
    double? keySpacing,
    double? keyElevation,
    Color? shadowColor,
    Gradient? primaryGradient,
  }) {
    return KeyboardTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      keyBackgroundColor: keyBackgroundColor ?? this.keyBackgroundColor,
      keyTextColor: keyTextColor ?? this.keyTextColor,
      specialKeyColor: specialKeyColor ?? this.specialKeyColor,
      specialKeyTextColor: specialKeyTextColor ?? this.specialKeyTextColor,
      activeKeyColor: activeKeyColor ?? this.activeKeyColor,
      keyBorderColor: keyBorderColor ?? this.keyBorderColor,
      keyBorderWidth: keyBorderWidth ?? this.keyBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      fontSize: fontSize ?? this.fontSize,
      keySpacing: keySpacing ?? this.keySpacing,
      keyElevation: keyElevation ?? this.keyElevation,
      shadowColor: shadowColor ?? this.shadowColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }
}
