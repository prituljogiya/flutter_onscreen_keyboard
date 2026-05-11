import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:get/get.dart';

import 'package:flutter_onscreen_keyboard_example/keyboard_demo_page.dart';

void main() {
  testWidgets('Shows on-screen keyboard demo', (WidgetTester tester) async {
    await tester.pumpWidget(const OnscreenKeyboardBinding(child: _TestRoot()));
    await tester.pumpAndSettle();

    expect(find.text('On-screen Keyboard Demo'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });
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
