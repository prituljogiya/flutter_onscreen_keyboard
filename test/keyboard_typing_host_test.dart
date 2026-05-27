import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard_init.dart';

void main() {
  setUp(() {
    FlutterOnscreenKeyboard.resetForTest();
    FlutterOnscreenKeyboard.configure(
      OnscreenKeyboardConfig.withColors(
        colors: const OnscreenKeyboardColors(
          background: Color(0xFF1E1E2C),
          keyBackground: Color(0xFF2A2A3D),
          keyText: Color(0xFFFFFFFF),
          specialKeyBackground: Color(0xFF3D3D56),
          specialKeyText: Color(0xFF00CFC1),
          activeKey: Color(0xFF4A3F8C),
          gradientTop: Color(0xFF353552),
          gradientBottom: Color(0xFF232336),
        ),
        useCustomKeyboard: true,
        replaceDefaultTheme: true,
      ),
    );
  });

  tearDown(FlutterOnscreenKeyboard.resetForTest);

  testWidgets('Host + OnscreenTextField typing does not throw', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      OnscreenKeyboardBinding(
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: OnscreenKeyboardHost(
                commitOnEnterOnly: true,
                child: Material(
                  child: OnscreenTextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OnscreenTextField));
    await tester.pumpAndSettle();

    final keys = find.text('h');
    if (keys.evaluate().isNotEmpty) {
      await tester.tap(keys.first);
      await tester.pump();
      await tester.tap(find.text('i').first);
      await tester.pumpAndSettle();
    }

    expect(find.byType(CustomKeyboard), findsOneWidget);
  });
}
