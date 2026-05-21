import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'keyboard_controller.dart';
import 'numericKeyController.dart';

/// Clears the on-screen keyboard validation message for [focusNode].
void clearOnscreenKeyboardValidation(FocusNode focusNode) {
  final tag = focusNode.hashCode.toString();
  if (Get.isRegistered<KeyboardController>(tag: tag)) {
    Get.find<KeyboardController>(tag: tag).clearValidation();
  }
  if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
    Get.find<NumericKeyboardController>(tag: tag).clearValidation();
  }
}

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

/// Drops GetX controllers tied to [focusNode] when the keyboard retargets fields.
void releaseOnscreenKeyboardControllers(FocusNode focusNode) {
  final tag = focusNode.hashCode.toString();
  if (Get.isRegistered<KeyboardController>(tag: tag)) {
    Get.delete<KeyboardController>(tag: tag);
  }
  if (Get.isRegistered<NumericKeyboardController>(tag: tag)) {
    Get.delete<NumericKeyboardController>(tag: tag);
  }
}
