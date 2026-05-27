import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// One named style with separate light/dark keyboard palettes + app chrome colors.
class DemoThemePreset {
  const DemoThemePreset({
    required this.name,
    required this.seedColor,
    required this.accentColor,
    required this.lightKeyboard,
    required this.darkKeyboard,
    required this.scaffoldLight,
    required this.scaffoldDark,
    required this.appBarColor,
  });

  final String name;
  final Color seedColor;
  final Color accentColor;
  final OnscreenKeyboardColors lightKeyboard;
  final OnscreenKeyboardColors darkKeyboard;
  final Color scaffoldLight;
  final Color scaffoldDark;
  final Color appBarColor;

  OnscreenKeyboardColors keyboardFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkKeyboard : lightKeyboard;
}

/// Demo branding + four keyboard theme presets (light and dark each).
abstract final class DemoAppTheme {
  DemoAppTheme._();

  static const List<DemoThemePreset> presets = [
    aurora,
    ocean,
    sunset,
    forest,
  ];

  /// Preset 1 — purple / cyan (default).
  static const DemoThemePreset aurora = DemoThemePreset(
    name: 'Aurora',
    seedColor: Color(0xFF4A3F8C),
    accentColor: Color(0xFF00CFC1),
    appBarColor: Color(0xFF4A3F8C),
    scaffoldLight: Color(0xFFF6F4FB),
    scaffoldDark: Color(0xFF15151E),
    lightKeyboard: OnscreenKeyboardColors(
      background: Color(0xFFEEEAFB),
      keyBackground: Color(0xFFFFFFFF),
      keyText: Color(0xFF1B1B2E),
      specialKeyBackground: Color(0xFFD4CCFC),
      specialKeyText: Color(0xFF4A3F8C),
      activeKey: Color(0xFF4A3F8C),
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
      previewBackground: Color(0xFFFFFFFF),
      previewText: Color(0xFF1B1B2E),
      previewBorder: Color(0x664A3F8C),
      chromeIcon: Color(0xFF4A3F8C),
    ),
    darkKeyboard: OnscreenKeyboardColors(
      background: Color(0xFF1E1E2C),
      keyBackground: Color(0xFF2A2A3D),
      keyText: Color(0xFFFFFFFF),
      specialKeyBackground: Color(0xFF3D3D56),
      specialKeyText: Color(0xFF00CFC1),
      activeKey: Color(0xFF4A3F8C),
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
      previewBackground: Color(0xFF2A2A3D),
      previewText: Color(0xFFFFFFFF),
      previewBorder: Color(0x66FFFFFF),
      chromeIcon: Color(0xFFFFFFFF),
    ),
  );

  /// Preset 2 — deep blue / aqua.
  static const DemoThemePreset ocean = DemoThemePreset(
    name: 'Ocean',
    seedColor: Color(0xFF1565C0),
    accentColor: Color(0xFF26C6DA),
    appBarColor: Color(0xFF0D47A1),
    scaffoldLight: Color(0xFFE8F4FC),
    scaffoldDark: Color(0xFF0A1628),
    lightKeyboard: OnscreenKeyboardColors(
      background: Color(0xFFE3F2FD),
      keyBackground: Color(0xFFFFFFFF),
      keyText: Color(0xFF0D47A1),
      specialKeyBackground: Color(0xFFBBDEFB),
      specialKeyText: Color(0xFF0277BD),
      activeKey: Color(0xFF1565C0),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFF90CAF9),
      keyBorder: Color(0x331565C0),
      shadow: Color(0x33000000),
      gradientTop: Color(0xFFFFFFFF),
      gradientBottom: Color(0xFFE1F5FE),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 2,
      previewBackground: Color(0xFFFFFFFF),
      previewText: Color(0xFF0D47A1),
      previewBorder: Color(0x661565C0),
      chromeIcon: Color(0xFF1565C0),
    ),
    darkKeyboard: OnscreenKeyboardColors(
      background: Color(0xFF0D2137),
      keyBackground: Color(0xFF153450),
      keyText: Color(0xFFE3F2FD),
      specialKeyBackground: Color(0xFF1E4976),
      specialKeyText: Color(0xFF26C6DA),
      activeKey: Color(0xFF1976D2),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFF1565C0),
      keyBorder: Color(0x6626C6DA),
      shadow: Color(0x99000000),
      gradientTop: Color(0xFF1A3A5C),
      gradientBottom: Color(0xFF0D2137),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 4,
      previewBackground: Color(0xFF153450),
      previewText: Color(0xFFE3F2FD),
      previewBorder: Color(0x6626C6DA),
      chromeIcon: Color(0xFF26C6DA),
    ),
  );

  /// Preset 3 — warm coral / amber.
  static const DemoThemePreset sunset = DemoThemePreset(
    name: 'Sunset',
    seedColor: Color(0xFFE65100),
    accentColor: Color(0xFFFFB74D),
    appBarColor: Color(0xFFD84315),
    scaffoldLight: Color(0xFFFFF8F0),
    scaffoldDark: Color(0xFF1A120C),
    lightKeyboard: OnscreenKeyboardColors(
      background: Color(0xFFFFF3E0),
      keyBackground: Color(0xFFFFFFFF),
      keyText: Color(0xFF4E342E),
      specialKeyBackground: Color(0xFFFFE0B2),
      specialKeyText: Color(0xFFE65100),
      activeKey: Color(0xFFE65100),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFFFFCC80),
      keyBorder: Color(0x33E65100),
      shadow: Color(0x33000000),
      gradientTop: Color(0xFFFFFFFF),
      gradientBottom: Color(0xFFFFECB3),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 2,
      previewBackground: Color(0xFFFFFFFF),
      previewText: Color(0xFF4E342E),
      previewBorder: Color(0x66E65100),
      chromeIcon: Color(0xFFE65100),
    ),
    darkKeyboard: OnscreenKeyboardColors(
      background: Color(0xFF2C1810),
      keyBackground: Color(0xFF3E2418),
      keyText: Color(0xFFFFF3E0),
      specialKeyBackground: Color(0xFF5D3520),
      specialKeyText: Color(0xFFFFB74D),
      activeKey: Color(0xFFE65100),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFFBF360C),
      keyBorder: Color(0x66FFB74D),
      shadow: Color(0x99000000),
      gradientTop: Color(0xFF4A2C1A),
      gradientBottom: Color(0xFF2C1810),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 4,
      previewBackground: Color(0xFF3E2418),
      previewText: Color(0xFFFFF3E0),
      previewBorder: Color(0x66FFB74D),
      chromeIcon: Color(0xFFFFB74D),
    ),
  );

  /// Preset 4 — green / mint.
  static const DemoThemePreset forest = DemoThemePreset(
    name: 'Forest',
    seedColor: Color(0xFF2E7D32),
    accentColor: Color(0xFF69F0AE),
    appBarColor: Color(0xFF1B5E20),
    scaffoldLight: Color(0xFFF1F8F2),
    scaffoldDark: Color(0xFF0E1A10),
    lightKeyboard: OnscreenKeyboardColors(
      background: Color(0xFFE8F5E9),
      keyBackground: Color(0xFFFFFFFF),
      keyText: Color(0xFF1B5E20),
      specialKeyBackground: Color(0xFFC8E6C9),
      specialKeyText: Color(0xFF2E7D32),
      activeKey: Color(0xFF2E7D32),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFFA5D6A7),
      keyBorder: Color(0x332E7D32),
      shadow: Color(0x33000000),
      gradientTop: Color(0xFFFFFFFF),
      gradientBottom: Color(0xFFC8E6C9),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 2,
      previewBackground: Color(0xFFFFFFFF),
      previewText: Color(0xFF1B5E20),
      previewBorder: Color(0x662E7D32),
      chromeIcon: Color(0xFF2E7D32),
    ),
    darkKeyboard: OnscreenKeyboardColors(
      background: Color(0xFF142218),
      keyBackground: Color(0xFF1E3324),
      keyText: Color(0xFFE8F5E9),
      specialKeyBackground: Color(0xFF2A4A32),
      specialKeyText: Color(0xFF69F0AE),
      activeKey: Color(0xFF388E3C),
      activeKeyText: Color(0xFFFFFFFF),
      keyPressed: Color(0xFF2E7D32),
      keyBorder: Color(0x6669F0AE),
      shadow: Color(0x99000000),
      gradientTop: Color(0xFF243D2C),
      gradientBottom: Color(0xFF142218),
      borderRadius: 10,
      keySpacing: 6,
      fontSize: 17,
      keyElevation: 4,
      previewBackground: Color(0xFF1E3324),
      previewText: Color(0xFFE8F5E9),
      previewBorder: Color(0x6669F0AE),
      chromeIcon: Color(0xFF69F0AE),
    ),
  );

  static DemoThemePreset presetAt(int index) =>
      presets[index.clamp(0, presets.length - 1)];

  /// Legacy aliases (first preset).
  static OnscreenKeyboardColors get keyboardLight => aurora.lightKeyboard;
  static OnscreenKeyboardColors get keyboardDark => aurora.darkKeyboard;

  static ThemeData materialTheme(Brightness brightness, DemoThemePreset preset) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: preset.seedColor,
      brightness: brightness,
      primary: preset.seedColor,
      secondary: preset.accentColor,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? preset.scaffoldDark : preset.scaffoldLight,
      appBarTheme: AppBarTheme(
        backgroundColor: preset.appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : preset.seedColor,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: preset.seedColor,
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
