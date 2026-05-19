import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/core/onscreen_keyboard_colors.dart';
import 'package:flutter_onscreen_keyboard/core/theme_controller.dart';

void main() {
  group('OnscreenKeyboardColors', () {
    const colors = OnscreenKeyboardColors(
      background: Color(0xFF111111),
      keyBackground: Color(0xFF222222),
      keyText: Color(0xFFFFFFFF),
      specialKeyBackground: Color(0xFF333333),
      specialKeyText: Color(0xFF00FF00),
      activeKey: Color(0xFF444444),
    );

    test('toTheme maps all required colors', () {
      final theme = colors.toTheme();
      expect(theme.backgroundColor, colors.background);
      expect(theme.keyBackgroundColor, colors.keyBackground);
      expect(theme.keyTextColor, colors.keyText);
      expect(theme.specialKeyColor, colors.specialKeyBackground);
      expect(theme.specialKeyTextColor, colors.specialKeyText);
      expect(theme.activeKeyColor, colors.activeKey);
      expect(theme.keyPressedColor, colors.activeKey);
      expect(theme.activeKeyTextColor, Colors.white);
    });

    test('KeyboardTheme.fromColors matches toTheme', () {
      final a = KeyboardTheme.fromColors(colors);
      final b = colors.toTheme();
      expect(a.backgroundColor, b.backgroundColor);
      expect(a.keyTextColor, b.keyTextColor);
      expect(a.activeKeyColor, b.activeKeyColor);
    });
  });
}
