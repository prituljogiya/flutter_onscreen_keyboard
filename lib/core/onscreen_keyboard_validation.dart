/// Shared validators for [OnscreenTextField] / custom keyboard Enter.
abstract final class OnscreenKeyboardValidators {
  OnscreenKeyboardValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns an error message when [value] is empty or not a valid email shape.
  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Enter your email';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null;
  }
}
