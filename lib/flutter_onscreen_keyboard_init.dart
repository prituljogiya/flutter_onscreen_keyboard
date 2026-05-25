import 'package:flutter/material.dart';

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
///   runApp(const OnscreenKeyboardBinding(child: MyApp()));
/// }
/// ```
abstract final class FlutterOnscreenKeyboard {
  FlutterOnscreenKeyboard._();

  static ThemeController? _themeController;

  /// Process-wide [ThemeController]. Created lazily by [ensureInitialized].
  static ThemeController get themeController {
    final tc = _themeController;
    if (tc != null) return tc;
    final created = ThemeController();
    _themeController = created;
    return created;
  }

  static OnscreenKeyboardConfig get config => globalOnscreenKeyboardConfig;

  static bool get useCustomKeyboard => useCustomOnscreenKeyboard;

  /// App-wide settings: custom theme, system vs on-screen keyboard, etc.
  static void configure(OnscreenKeyboardConfig config) {
    setGlobalOnscreenKeyboardConfig(config);
    ensureInitialized();
    _applyConfigToThemeController();
  }

  static void ensureInitialized() {
    _themeController ??= ThemeController();
    _applyConfigToThemeController();
  }

  static void _applyConfigToThemeController() {
    final tc = _themeController;
    if (tc == null) return;
    final cfg = globalOnscreenKeyboardConfig;
    final theme = cfg.keyboardTheme;
    if (theme != null && cfg.replaceDefaultTheme) {
      tc.updateTheme(theme);
    }
  }

  /// Disposes the shared [ThemeController] and resets global config. Intended
  /// for test isolation; do not call from app code.
  @visibleForTesting
  static void resetForTest() {
    _themeController?.dispose();
    _themeController = null;
    setGlobalOnscreenKeyboardConfig(OnscreenKeyboardConfig.defaults);
  }
}

/// Wrap your [MaterialApp] [home] (or the whole app tree) so the plugin
/// registers its dependencies once. Safe to place at the root.
class OnscreenKeyboardBinding extends StatelessWidget {
  const OnscreenKeyboardBinding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    FlutterOnscreenKeyboard.ensureInitialized();
    return OnscreenKeyboardThemeScope(
      controller: FlutterOnscreenKeyboard.themeController,
      child: child,
    );
  }
}

/// Inherited [ThemeController] for keyboard widgets to listen to.
class OnscreenKeyboardThemeScope extends InheritedNotifier<ThemeController> {
  const OnscreenKeyboardThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OnscreenKeyboardThemeScope>();
    return scope?.notifier;
  }
}
