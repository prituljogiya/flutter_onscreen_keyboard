import 'package:flutter/services.dart';

/// Whether a [TextField.keyboardType] (or equivalent) should use the package
/// [NumericKeyboard] instead of [CustomKeyboard].
///
/// Treats [TextInputType.number], [TextInputType.phone], and common
/// [TextInputType.numberWithOptions] combinations as numeric. Everything else
/// (including [TextInputType.text], [TextInputType.emailAddress], …) uses the
/// alphabetic [CustomKeyboard].
bool preferOnscreenNumericKeyboard(TextInputType keyboardType) {
  if (keyboardType == TextInputType.number) return true;
  if (keyboardType == TextInputType.phone) return true;

  const variants = <TextInputType>[
    TextInputType.numberWithOptions(),
    TextInputType.numberWithOptions(decimal: true),
    TextInputType.numberWithOptions(signed: true),
    TextInputType.numberWithOptions(signed: true, decimal: true),
    TextInputType.numberWithOptions(signed: false, decimal: true),
  ];
  for (final v in variants) {
    if (keyboardType == v) return true;
  }
  return false;
}
