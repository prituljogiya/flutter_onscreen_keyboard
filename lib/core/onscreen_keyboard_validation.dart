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
