import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'onscreen_keyboard_config.dart';
import 'theme_controller.dart';

/// Resolves which [KeyboardTheme] to paint for keyboard widgets.
///
/// Priority: per-widget override → [OnscreenKeyboardConfig.keyboardTheme] →
/// [ThemeController.keyboardTheme].
KeyboardTheme resolveKeyboardTheme([KeyboardTheme? widgetOverride]) {
  if (widgetOverride != null) return widgetOverride;
  final configured = globalOnscreenKeyboardConfig.keyboardTheme;
  if (configured != null) return configured;
  if (Get.isRegistered<ThemeController>()) {
    return Get.find<ThemeController>().keyboardTheme;
  }
  return KeyboardTheme.purpleCyan();
}

/// Builds a keyboard subtree, listening to [ThemeController] when no fixed
/// global / widget theme is set.
Widget buildKeyboardWithResolvedTheme({
  required KeyboardTheme? widgetOverride,
  required Widget Function(KeyboardTheme theme) builder,
}) {
  final fixed = widgetOverride ?? globalOnscreenKeyboardConfig.keyboardTheme;
  if (fixed != null) {
    return builder(fixed);
  }
  if (!Get.isRegistered<ThemeController>()) {
    return builder(KeyboardTheme.purpleCyan());
  }
  return Obx(() {
    Get.find<ThemeController>().keyboardThemeRx.value;
    return builder(resolveKeyboardTheme(null));
  });
}
