import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// App keyboard palette — add your colors here and use everywhere.
abstract final class AppKeyboardTheme {
  AppKeyboardTheme._();

  static const OnscreenKeyboardColors colors = OnscreenKeyboardColors(
    background: Color(0xFF2D004D),
    keyBackground: Color(0xFF3D0F5C),
    keyText: Color(0xFFE0D0FF),
    specialKeyBackground: Color(0xFF4A1A6B),
    specialKeyText: Color(0xFF00E5D4),
    activeKey: Color(0xFF31AC6F),
    keyPressed: Color(0xFF31AC6F),
    activeKeyText: Colors.white,
    keyBorder: Color(0x805A3A7A),
    shadow: Colors.black,
    gradientTop: Color(0xFF4A1A6B),
    gradientBottom: Color(0xFF2D0A4A),
  );

  static KeyboardTheme get theme => colors.toTheme();
}
