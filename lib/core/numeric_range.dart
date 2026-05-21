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
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (!allowIncomplete) {
        return 'Enter a number';
      }
      if (min != null || max != null || integersOnly) {
        return 'Enter a number';
      }
      return null;
    }

    if (min == null && max == null && !integersOnly) return null;

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

  /// Digit count allowed before `.` derived from [max] (e.g. 59 → 2).
  static int wholeNumberDigitsForBound(num max) {
    final whole = max.abs().truncate();
    if (whole == 0) return 1;
    return whole.toString().length;
  }

  /// Fractional digit count allowed after `.` derived from a bound (e.g. 5.5 → 1).
  static int fractionalDigitsForBound(num bound) {
    final text = formatBound(bound);
    final dot = text.indexOf('.');
    if (dot < 0) return 0;
    return text.substring(dot + 1).length;
  }

  /// Uses both [min] and [max] so e.g. 0.5–500 still allows one decimal place.
  static int fractionalDigitsForRange({num? min, num? max}) {
    var digits = 0;
    if (min != null) {
      digits = digits < fractionalDigitsForBound(min)
          ? fractionalDigitsForBound(min)
          : digits;
    }
    if (max != null) {
      final maxFrac = fractionalDigitsForBound(max);
      digits = digits < maxFrac ? maxFrac : digits;
    }
    return digits;
  }

  static int wholeNumberDigitsForRange({num? min, num? max}) {
    var digits = 0;
    if (min != null) {
      digits = digits < wholeNumberDigitsForBound(min)
          ? wholeNumberDigitsForBound(min)
          : digits;
    }
    if (max != null) {
      final maxWhole = wholeNumberDigitsForBound(max);
      digits = digits < maxWhole ? maxWhole : digits;
    }
    return digits == 0 ? 1 : digits;
  }

  /// Whether [value] respects digit limits implied by [min] / [max].
  static bool isWithinMaxDigitLength(
    String value, {
    num? min,
    num? max,
    bool integersOnly = false,
  }) {
    if (min == null && max == null) return true;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;

    final dotIndex = trimmed.indexOf('.');
    final intPart = dotIndex < 0 ? trimmed : trimmed.substring(0, dotIndex);
    if (intPart.length > wholeNumberDigitsForRange(min: min, max: max)) {
      return false;
    }

    if (!integersOnly && dotIndex >= 0) {
      final frac = trimmed.substring(dotIndex + 1);
      if (frac.length > fractionalDigitsForRange(min: min, max: max)) {
        return false;
      }
    }
    return true;
  }

  /// Whether [value] fits [maxLength] (e.g. access code exactly 4 digits).
  static bool isWithinMaxLength(String value, int? maxLength) {
    if (maxLength == null) return true;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '0') return true;
    return trimmed.length <= maxLength;
  }

  /// Simulates appending [digit] to [currentText] (same rules as the numeric pad).
  static bool canAcceptDigit({
    required String currentText,
    required String digit,
    num? min,
    num? max,
    bool integersOnly = false,
    int? maxLength,
  }) {
    final String newText;
    if ((currentText.isEmpty || currentText == '0') && digit != '.') {
      newText = digit;
    } else {
      newText = currentText + digit;
    }

    if (!isWithinMaxLength(newText, maxLength)) return false;
    if (min == null && max == null) return true;
    return isWithinMaxDigitLength(
      newText,
      min: min,
      max: max,
      integersOnly: integersOnly,
    );
  }
}
