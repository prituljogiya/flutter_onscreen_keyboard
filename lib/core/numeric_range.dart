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
  ///
  /// Reject rules, in order:
  /// 1. [maxLength] cap (e.g. an access code that must be exactly 4 chars).
  /// 2. Whole-digit cap derived from [max] — the integer part of [newText]
  ///    is limited to the digit width of [max]. So with `max: 500` the user
  ///    can type any 1–3-digit integer (`555` is typeable so they see the
  ///    "Must be <= 500" error), but `5555` is silently rejected because
  ///    even the digit count already exceeds the bound.
  /// 3. Explicit [maxFractionDigits] cap. [min] / [max] do **not** impose
  ///    a fractional limit on their own — fractional length is unlimited
  ///    unless [maxFractionDigits] is set.
  ///
  /// The numeric value of [newText] is intentionally NOT compared against
  /// [max] here. That check lives in the live validator so the user sees
  /// an actionable "Must be <= max" message and Enter is blocked until they
  /// back off. [min] is not enforced at all per-keystroke — the user might
  /// still be building up to a valid number (e.g. "5" → "55" → "550" in a
  /// 10-500 field). The full `min` check runs in [validate] on Enter.
  static bool canAcceptDigit({
    required String currentText,
    required String digit,
    num? min,
    num? max,
    bool integersOnly = false,
    int? maxLength,
    int? maxFractionDigits,
  }) {
    final String newText;
    if ((currentText.isEmpty || currentText == '0') && digit != '.') {
      newText = digit;
    } else {
      newText = currentText + digit;
    }

    if (!isWithinMaxLength(newText, maxLength)) return false;

    if (max != null && !_isWithinMaxWholeDigits(newText, max)) {
      return false;
    }

    if (!integersOnly &&
        maxFractionDigits != null &&
        !_isWithinMaxFractionDigits(newText, maxFractionDigits)) {
      return false;
    }

    return true;
  }

  /// True when the integer part of [newText] does not exceed the digit
  /// width of [max] (e.g. `max: 500` allows up to 3 whole digits).
  static bool _isWithinMaxWholeDigits(String newText, num max) {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return true;
    final dot = trimmed.indexOf('.');
    final intPart = dot < 0 ? trimmed : trimmed.substring(0, dot);
    return intPart.length <= wholeNumberDigitsForBound(max);
  }

  /// True when [newText] has at most [maxFractionDigits] digits after `.`.
  ///
  /// `0.` (incomplete decimal) passes any cap so the user can still tap `.`
  /// before deciding whether to type a fractional digit.
  static bool _isWithinMaxFractionDigits(String newText, int maxFractionDigits) {
    final dot = newText.indexOf('.');
    if (dot < 0) return true;
    final frac = newText.substring(dot + 1);
    return frac.length <= maxFractionDigits;
  }

  /// True when [newText] parsed as a number is <= [max].
  ///
  /// Treats an incomplete decimal (trailing `.`) as the integer part, so the
  /// user can still type "500." in a 0.5–500 weight field before deciding
  /// whether to add a fractional digit.
  static bool _isAtOrBelowMax(String newText, num max) {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return true;
    final parseText =
        trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (parseText.isEmpty) return true;
    final n = num.tryParse(parseText);
    if (n == null) return true;
    return n <= max;
  }
}
