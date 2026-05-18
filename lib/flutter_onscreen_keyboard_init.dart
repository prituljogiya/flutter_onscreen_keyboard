import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/keyboard_theme_resolver.dart';
import 'core/onscreen_keyboard_config.dart';
import 'core/theme_controller.dart';

export 'core/onscreen_keyboard_config.dart';
export 'core/keyboard_theme_resolver.dart';

/// Call once before [runApp] **or** rely on [OnscreenKeyboardBinding] below.
///
/// Use [configure] with [OnscreenKeyboardConfig.withColors] and your
/// [OnscreenKeyboardColors] class (all colors in one place). That replaces
/// plugin defaults. Set [OnscreenKeyboardConfig.useCustomKeyboard] to switch
/// between the on-screen keyboard and the system IME (code only, no UI).
///
/// Wrap screens with [OnscreenKeyboardHost] and fields with [OnscreenTextField]
/// to replace the default keyboard across the app.
///
/// ```dart
/// void main() {
///   FlutterOnscreenKeyboard.configure(
///     const OnscreenKeyboardConfig(
///       useCustomKeyboard: true,
///       keyboardTheme: KeyboardTheme.purpleCyan(),
///       replaceDefaultTheme: true,
///     ),
///   );
///   runApp(GetMaterialApp(home: OnscreenKeyboardBinding(child: MyApp())));
/// }
/// ```
abstract final class FlutterOnscreenKeyboard {
  FlutterOnscreenKeyboard._();

  static OnscreenKeyboardConfig get config => globalOnscreenKeyboardConfig;

  static bool get useCustomKeyboard => useCustomOnscreenKeyboard;

  /// App-wide settings: custom theme, system vs on-screen keyboard, etc.
  static void configure(OnscreenKeyboardConfig config) {
    setGlobalOnscreenKeyboardConfig(config);
    ensureInitialized();
    _applyConfigToThemeController();
  }

  static void ensureInitialized() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
    _applyConfigToThemeController();
  }

  static void _applyConfigToThemeController() {
    if (!Get.isRegistered<ThemeController>()) return;
    final cfg = globalOnscreenKeyboardConfig;
    final theme = cfg.keyboardTheme;
    if (theme != null && cfg.replaceDefaultTheme) {
      Get.find<ThemeController>().updateTheme(theme);
    }
  }

}

/// Wrap your [GetMaterialApp] [home] (or the whole app tree) so the plugin
/// registers its dependencies once. Safe to place at the root.
class OnscreenKeyboardBinding extends StatelessWidget {
  const OnscreenKeyboardBinding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    FlutterOnscreenKeyboard.ensureInitialized();
    return child;
  }
}
