import 'onscreen_keyboard_colors.dart';
import 'theme_controller.dart';

/// App-wide plugin settings. Set once via [FlutterOnscreenKeyboard.configure]
/// before [runApp] (or in `main` right after [FlutterOnscreenKeyboard.ensureInitialized]).
class OnscreenKeyboardConfig {
  const OnscreenKeyboardConfig({
    this.useCustomKeyboard = true,
    this.keyboardTheme,
    this.replaceDefaultTheme = true,
    this.lockKeyboardTheme = false,
  });

  /// When `false`, [OnscreenTextField] and [OnscreenKeyboardHost] use the
  /// platform [TextField] / IME (system keyboard). No UI toggle — code only.
  final bool useCustomKeyboard;

  /// When set and [replaceDefaultTheme] is true, this palette replaces the
  /// plugin's built-in light/dark keyboard themes for the whole app.
  final KeyboardTheme? keyboardTheme;

  /// Applies [keyboardTheme] to [ThemeController] on configure / init.
  final bool replaceDefaultTheme;

  /// When true, [ThemeController.toggleTheme] does not swap built-in palettes
  /// (keeps your configured [keyboardTheme]).
  final bool lockKeyboardTheme;

  static const defaults = OnscreenKeyboardConfig();

  /// Configure the plugin from [OnscreenKeyboardColors] (recommended).
  factory OnscreenKeyboardConfig.withColors({
    required OnscreenKeyboardColors colors,
    bool useCustomKeyboard = true,
    bool replaceDefaultTheme = true,
    bool lockKeyboardTheme = false,
  }) {
    return OnscreenKeyboardConfig(
      useCustomKeyboard: useCustomKeyboard,
      keyboardTheme: colors.toTheme(),
      replaceDefaultTheme: replaceDefaultTheme,
      lockKeyboardTheme: lockKeyboardTheme,
    );
  }

  OnscreenKeyboardConfig copyWith({
    bool? useCustomKeyboard,
    KeyboardTheme? keyboardTheme,
    bool? replaceDefaultTheme,
    bool? lockKeyboardTheme,
  }) {
    return OnscreenKeyboardConfig(
      useCustomKeyboard: useCustomKeyboard ?? this.useCustomKeyboard,
      keyboardTheme: keyboardTheme ?? this.keyboardTheme,
      replaceDefaultTheme: replaceDefaultTheme ?? this.replaceDefaultTheme,
      lockKeyboardTheme: lockKeyboardTheme ?? this.lockKeyboardTheme,
    );
  }
}

OnscreenKeyboardConfig _globalOnscreenKeyboardConfig =
    OnscreenKeyboardConfig.defaults;

OnscreenKeyboardConfig get globalOnscreenKeyboardConfig =>
    _globalOnscreenKeyboardConfig;

void setGlobalOnscreenKeyboardConfig(OnscreenKeyboardConfig config) {
  _globalOnscreenKeyboardConfig = config;
}

bool get useCustomOnscreenKeyboard =>
    _globalOnscreenKeyboardConfig.useCustomKeyboard;
