import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme_controller.dart';
import '../flutter_onscreen_keyboard_init.dart';

/// Minimal runnable app: one [GetMaterialApp] whose `home` is [child].
///
/// For a real app you already have a root [GetMaterialApp], use
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

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          home: child,
        );
      },
    );
  }
}
