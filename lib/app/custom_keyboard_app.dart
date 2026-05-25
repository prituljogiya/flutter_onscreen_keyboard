import 'package:flutter/material.dart';

import '../flutter_onscreen_keyboard_init.dart';

/// Minimal runnable app: one [MaterialApp] whose `home` is [child].
///
/// For a real app you already have a root [MaterialApp], use
/// [FlutterOnscreenKeyboard.ensureInitialized] in `main` and/or wrap with
/// [OnscreenKeyboardBinding] instead of this widget.
class CustomKeyboardApp extends StatelessWidget {
  final Widget child;

  const CustomKeyboardApp({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    FlutterOnscreenKeyboard.ensureInitialized();

    final controller = FlutterOnscreenKeyboard.themeController;
    return OnscreenKeyboardBinding(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: controller.lightTheme,
            darkTheme: controller.darkTheme,
            themeMode: controller.themeMode,
            home: child,
          );
        },
      ),
    );
  }
}
