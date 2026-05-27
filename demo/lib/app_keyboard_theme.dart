import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// Demo app branding + keyboard palettes.
///
/// Customize every keyboard color here, then pass the matching palette to
/// [FlutterOnscreenKeyboard.configure] and [ThemeController.applyKeyboardColors]
/// when toggling light/dark mode.
abstract final class DemoAppTheme {
  DemoAppTheme._();

  static const Color primary = Color(0xFF4A3F8C);
  static const Color accent = Color(0xFF00CFC1);

  static const OnscreenKeyboardColors keyboardDark = OnscreenKeyboardColors(
    background: Color(0xFF1E1E2C),
    keyBackground: Color(0xFF2A2A3D),
    keyText: Color(0xFFFFFFFF),
    specialKeyBackground: Color(0xFF3D3D56),
    specialKeyText: accent,
    activeKey: primary,
    activeKeyText: Color(0xFFFFFFFF),
    keyPressed: Color(0xFF5C57B6),
    keyBorder: Color(0x66FFFFFF),
    shadow: Color(0x99000000),
    gradientTop: Color(0xFF353552),
    gradientBottom: Color(0xFF232336),
    borderRadius: 10,
    keySpacing: 6,
    fontSize: 17,
    keyElevation: 4,
  );

  static const OnscreenKeyboardColors keyboardLight = OnscreenKeyboardColors(
    background: Color(0xFFEEEAFB),
    keyBackground: Color(0xFFFFFFFF),
    keyText: Color(0xFF1B1B2E),
    specialKeyBackground: Color(0xFFD4CCFC),
    specialKeyText: primary,
    activeKey: primary,
    activeKeyText: Color(0xFFFFFFFF),
    keyPressed: Color(0xFFB8AEF7),
    keyBorder: Color(0x334A3F8C),
    shadow: Color(0x33000000),
    gradientTop: Color(0xFFFFFFFF),
    gradientBottom: Color(0xFFF3F0FC),
    borderRadius: 10,
    keySpacing: 6,
    fontSize: 17,
    keyElevation: 2,
  );

  static ThemeData materialTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: accent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF15151E) : const Color(0xFFF6F4FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : primary,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
