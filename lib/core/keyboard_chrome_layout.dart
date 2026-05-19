import 'package:flutter/material.dart';

/// Chrome row heights inside the keyboard column (error / min-max labels).
abstract final class KeyboardChromeLayout {
  KeyboardChromeLayout._();

  /// Preview row: 50px field + margins (10 top, 3 bottom).
  static const double numericPreviewChrome = 63;
  static const double errorChrome = 20;
  static const double boundsChrome = 24;
  /// Top + bottom padding around the digit grid in [NumericKeyboard].
  static const double numericKeysVerticalPadding = 14;

  static double numericKeysFraction(bool isLandscape) =>
      isLandscape ? 0.30 : 0.28;

  static double customKeysFraction(bool isLandscape) =>
      isLandscape ? 0.44 : 0.36;

  static const double customPreviewChrome = 53;

  /// Panel height = preview + keys + optional chrome rows (nothing reserved when hidden).
  static double numericPanelHeight({
    required BuildContext context,
    required bool isLandscape,
    required bool showError,
    required bool showBounds,
    double? overrideHeight,
  }) {
    if (overrideHeight != null) return overrideHeight;

    final keysH =
        MediaQuery.sizeOf(context).height * numericKeysFraction(isLandscape);
    var total =
        numericPreviewChrome + keysH + numericKeysVerticalPadding;
    if (showError) total += errorChrome;
    if (showBounds) total += boundsChrome;
    return total;
  }

  static double customPanelHeight({
    required BuildContext context,
    required bool isLandscape,
    required bool showError,
    required bool showBounds,
    double? overrideHeight,
  }) {
    if (overrideHeight != null) return overrideHeight;

    final keysH =
        MediaQuery.sizeOf(context).height * customKeysFraction(isLandscape);
    var total = customPreviewChrome + keysH;
    if (showError) total += errorChrome;
    if (showBounds) total += boundsChrome;
    return total;
  }
}
