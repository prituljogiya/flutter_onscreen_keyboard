import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:get/get.dart';

import 'keyboard_demo_page.dart';

void main() {
  runApp(const OnscreenKeyboardBinding(child: _KeyboardDemoRoot()));
}

/// One [GetMaterialApp] for the whole app — keyboards work on every screen.
class _KeyboardDemoRoot extends StatelessWidget {
  const _KeyboardDemoRoot();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (tc) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: tc.lightTheme,
          darkTheme: tc.darkTheme,
          themeMode: tc.themeMode,
          home: const KeyboardDemoPage(),
        );
      },
    );
  }
}
