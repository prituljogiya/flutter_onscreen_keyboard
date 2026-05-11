import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
    final brightness = PlatformDispatcher.instance.platformBrightness;

    _isDarkMode.value = brightness == Brightness.dark;

    _keyboardTheme.value = _isDarkMode.value
        ? KeyboardTheme.darkTheme()
        : KeyboardTheme.lightTheme();
  }

  void updateTheme(KeyboardTheme newTheme) {
    _keyboardTheme.value = newTheme;
  }

  void toggleTheme() {
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
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF2D004D)
          : const Color(0xFFF3E5F5),
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
}
