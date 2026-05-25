import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

import 'app_keyboard_theme.dart';
import 'keyboard_demo_page.dart';

/// Code-level switch: `false` uses the system keyboard, `true` uses this plugin.
/// Override at build time: `--dart-define=USE_CUSTOM_KEYBOARD=false`
const bool kUseCustomOnscreenKeyboard = bool.fromEnvironment(
  'USE_CUSTOM_KEYBOARD',
  defaultValue: true,
);

void main() {
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: AppKeyboardTheme.colors,
      useCustomKeyboard: kUseCustomOnscreenKeyboard,
      replaceDefaultTheme: true,
      lockKeyboardTheme: kDebugMode,
    ),
  );

  runApp(const OnscreenKeyboardBinding(child: _KeyboardDemoRoot()));
}

/// One [MaterialApp] for the whole app — keyboards work on every screen.
class _KeyboardDemoRoot extends StatelessWidget {
  const _KeyboardDemoRoot();

  @override
  Widget build(BuildContext context) {
    final tc = FlutterOnscreenKeyboard.themeController;
    return ListenableBuilder(
      listenable: tc,
      builder: (context, _) {
        return MaterialApp(
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
