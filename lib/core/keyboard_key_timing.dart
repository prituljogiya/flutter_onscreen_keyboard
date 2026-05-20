/// Shared timing for on-screen key press feedback (snappy, system-keyboard feel).
abstract final class KeyboardKeyTiming {
  KeyboardKeyTiming._();

  /// Key shrink/highlight animation while pressed.
  static const Duration pressAnimation = Duration(milliseconds: 40);

  /// Brief flash on the last pressed key (custom keyboard layout).
  static const Duration flashHighlight = Duration(milliseconds: 80);

  /// Hold before backspace-style repeat (system keyboard-like).
  static const Duration repeatInitialDelay = Duration(milliseconds: 350);

  static const Duration repeatInterval = Duration(milliseconds: 40);

  static const Duration longPressDelay = Duration(milliseconds: 450);
}
