import 'package:flutter/material.dart';

/// Returns false when [controller] was disposed (e.g. keyboard closed mid-tap).
bool isTextEditingControllerUsable(TextEditingController controller) {
  try {
    // Reading value throws after [TextEditingController.dispose].
    // ignore: unnecessary_statements
    controller.value;
    return true;
  } catch (_) {
    return false;
  }
}
