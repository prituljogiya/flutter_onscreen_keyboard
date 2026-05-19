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
