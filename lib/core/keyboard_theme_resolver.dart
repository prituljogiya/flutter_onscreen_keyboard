import 'package:flutter/material.dart';

import '../flutter_onscreen_keyboard_init.dart';
import 'theme_controller.dart';

/// Resolves which [KeyboardTheme] to paint for keyboard widgets.
///
/// Priority: per-widget override → [OnscreenKeyboardConfig.keyboardTheme] →
/// scoped [OnscreenKeyboardThemeScope] / [FlutterOnscreenKeyboard.themeController].
KeyboardTheme resolveKeyboardTheme([
  KeyboardTheme? widgetOverride,
  BuildContext? context,
]) {
  if (widgetOverride != null) return widgetOverride;
  final configured = globalOnscreenKeyboardConfig.keyboardTheme;
  if (configured != null) return configured;
  final scoped =
      context == null ? null : OnscreenKeyboardThemeScope.maybeOf(context);
  if (scoped != null) return scoped.keyboardTheme;
  return FlutterOnscreenKeyboard.themeController.keyboardTheme;
}

/// Builds a keyboard subtree, listening to [ThemeController] when no fixed
/// global / widget theme is set so palette changes repaint the keys.
Widget buildKeyboardWithResolvedTheme({
  required KeyboardTheme? widgetOverride,
  required Widget Function(KeyboardTheme theme) builder,
  BuildContext? context,
}) {
  final fixed = widgetOverride ?? globalOnscreenKeyboardConfig.keyboardTheme;
  if (fixed != null) {
    return builder(fixed);
  }

  final controller = (context != null
          ? OnscreenKeyboardThemeScope.maybeOf(context)
          : null) ??
      FlutterOnscreenKeyboard.themeController;

  return ListenableBuilder(
    listenable: controller,
    builder: (context, _) => builder(controller.keyboardTheme),
  );
}
