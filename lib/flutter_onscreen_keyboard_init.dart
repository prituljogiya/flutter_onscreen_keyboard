import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/theme_controller.dart';

/// Call once before [runApp] **or** rely on [OnscreenKeyboardBinding] below.
///
/// Registers [ThemeController] so `CustomKeyboard`, `NumericKeyboard`,
/// and `DraggableDynamicKeyboard` work anywhere under your root
/// [GetMaterialApp].
///
/// ```dart
/// void main() {
///   FlutterOnscreenKeyboard.ensureInitialized();
///   runApp(GetMaterialApp(home: MyApp()));
/// }
/// ```
abstract final class FlutterOnscreenKeyboard {
  FlutterOnscreenKeyboard._();

  static void ensureInitialized() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
  }
}

/// Wrap your [GetMaterialApp] [home] (or the whole app tree) so the plugin
/// registers its dependencies once. Safe to place at the root.
///
/// ```dart
/// runApp(GetMaterialApp(
///   theme: ThemeData.light(),
///   home: OnscreenKeyboardBinding(child: MyShell()),
/// ));
/// ```
///
/// For app-wide dark/light from the plugin theme controller, use
/// [GetBuilder] around [GetMaterialApp] (see example `main.dart`).
class OnscreenKeyboardBinding extends StatelessWidget {
  const OnscreenKeyboardBinding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    FlutterOnscreenKeyboard.ensureInitialized();
    return child;
  }
}
