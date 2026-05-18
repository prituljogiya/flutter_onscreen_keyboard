import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_onscreen_keyboard_example/app_keyboard_theme.dart';
import 'package:flutter_onscreen_keyboard_example/keyboard_demo_page.dart';

const customKeyboardPreviewKey = ValueKey<String>('customKeyboardPreview');

/// Resets GetX and applies plugin config before each test group.
void configureKeyboardTests({required bool useCustomKeyboard}) {
  Get.testMode = true;
  Get.reset();
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: AppKeyboardTheme.colors,
      useCustomKeyboard: useCustomKeyboard,
      replaceDefaultTheme: true,
    ),
  );
}

void tearDownKeyboardTests() {
  Get.reset();
}

void bindLargeTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
}

void resetTestViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> pumpKeyboardDemo(WidgetTester tester) async {
  bindLargeTestViewport(tester);
  await tester.pumpWidget(const OnscreenKeyboardBinding(child: _TestRoot()));
  await tester.pumpAndSettle();
}

Future<void> dismissOpenKeyboard(WidgetTester tester) async {
  final close = find.byIcon(Icons.close);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.first);
    await tester.pumpAndSettle();
  }
}

class _TestRoot extends StatelessWidget {
  const _TestRoot();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (tc) {
        return GetMaterialApp(
          theme: tc.lightTheme,
          darkTheme: tc.darkTheme,
          themeMode: tc.themeMode,
          home: const KeyboardDemoPage(),
        );
      },
    );
  }
}

Future<void> tapField(WidgetTester tester, String fieldKey) async {
  final finder = find.byKey(ValueKey<String>(fieldKey));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapKeyLabel(WidgetTester tester, String label) async {
  final matches = find.text(label);
  expect(matches, findsWidgets);
  await tester.tap(matches.last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 260));
}

Future<void> typeAlpha(WidgetTester tester, String text) async {
  for (final codeUnit in text.codeUnits) {
    final ch = String.fromCharCode(codeUnit);
    await tapKeyLabel(tester, ch);
  }
}

Future<void> typeDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tapKeyLabel(tester, d);
  }
}

Future<void> tapEnter(WidgetTester tester) async {
  await tapKeyLabel(tester, 'Enter');
  await tester.pumpAndSettle();
}

TextField readField(WidgetTester tester, String fieldKey) {
  return tester.widget<TextField>(find.byKey(ValueKey<String>(fieldKey)));
}

String fieldText(WidgetTester tester, String fieldKey) {
  return readField(tester, fieldKey).controller!.text;
}
