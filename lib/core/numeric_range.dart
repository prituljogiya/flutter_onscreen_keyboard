/// Helpers for numeric keyboard min/max validation (integers and decimals).
abstract final class NumericRange {
  NumericRange._();

  /// True while the user is still typing a fractional part (e.g. `3.`).
  static bool isIncompleteDecimal(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('.') && trimmed.length > 1;
  }

  /// After `.`, digits are present (e.g. `2.2`). For [integersOnly], rejects
  /// non-whole values immediately; `2.` alone is not matched (still typing).
  static String? integersOnlyFractionError(
    String trimmed, {
    required bool allowIncomplete,
  }) {
    if (allowIncomplete && isIncompleteDecimal(trimmed)) return null;

    final dot = trimmed.indexOf('.');
    if (dot < 0) return null;

    final afterDot = trimmed.substring(dot + 1);
    if (afterDot.isEmpty) return null;

    final n = num.tryParse(trimmed);
    if (n == null) return 'Enter a valid number';
    if (!_isWholeNumber(n)) return 'Whole numbers only';
    return null;
  }

  static String? validate(
    String value, {
    num? min,
    num? max,
    bool integersOnly = false,
    bool allowIncomplete = true,
  }) {
    if (min == null && max == null && !integersOnly) return null;

    final trimmed = value.trim();
    if (allowIncomplete && isIncompleteDecimal(trimmed)) return null;

    if (integersOnly) {
      final fractionError = integersOnlyFractionError(
        trimmed,
        allowIncomplete: allowIncomplete,
      );
      if (fractionError != null) return fractionError;
    }

    final n = num.tryParse(trimmed);
    if (n == null) {
      return 'Enter a valid number';
    }

    if (integersOnly && !_isWholeNumber(n)) {
      return 'Whole numbers only';
    }

    if (min != null && n < min) {
      return 'Must be >= ${formatBound(min)}';
    }
    if (max != null && n > max) {
      return 'Must be <= ${formatBound(max)}';
    }
    return null;
  }

  /// Staging text committed to the field (e.g. `10.0` → `10` for integer fields).
  static String commitText(String value, {bool integersOnly = false}) {
    final trimmed = value.trim();
    if (!integersOnly) return trimmed;

    final n = num.tryParse(trimmed);
    if (n == null || !_isWholeNumber(n)) return trimmed;
    return n.round().toInt().toString();
  }

  static bool _isWholeNumber(num n) => n == n.roundToDouble();

  static String formatBound(num value) {
    if (value is int) return value.toString();
    final d = value.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    final text = d.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
