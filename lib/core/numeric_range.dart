/// Helpers for numeric keyboard min/max validation (integers and decimals).
abstract final class NumericRange {
  NumericRange._();

  static String? validate(String value, {num? min, num? max}) {
    if (min == null && max == null) return null;

    final n = num.tryParse(value.trim());
    if (n == null) {
      return 'Enter a valid number';
    }

    if (min != null && n < min) {
      return 'Must be >= ${formatBound(min)}';
    }
    if (max != null && n > max) {
      return 'Must be <= ${formatBound(max)}';
    }
    return null;
  }

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
