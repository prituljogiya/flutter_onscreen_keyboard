import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard_init.dart';

void main() {
  setUp(() {
    FlutterOnscreenKeyboard.resetForTest();
    FlutterOnscreenKeyboard.configure(
      const OnscreenKeyboardConfig(
        useCustomKeyboard: true,
        replaceDefaultTheme: true,
      ),
    );
  });

  tearDown(FlutterOnscreenKeyboard.resetForTest);

  testWidgets('CustomKeyboard typing does not throw', (tester) async {
    final fieldController = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      OnscreenKeyboardBinding(
        child: MaterialApp(
          home: Scaffold(
            body: CustomKeyboard(
              controller: fieldController,
              focusNode: focusNode,
              commitOnEnterOnly: true,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('a').first);
    await tester.pump();
    await tester.tap(find.text('b').first);
    await tester.pump();
    await tester.tap(find.text('c').first);
    await tester.pumpAndSettle();

    expect(find.byType(CustomKeyboard), findsOneWidget);
  });

  testWidgets('NumericKeyboard typing does not throw', (tester) async {
    final fieldController = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      OnscreenKeyboardBinding(
        child: MaterialApp(
          home: Scaffold(
            body: NumericKeyboard(
              controller: fieldController,
              focusNode: focusNode,
              commitOnEnterOnly: true,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1').first);
    await tester.pump();
    await tester.tap(find.text('2').first);
    await tester.pump();
    await tester.tap(find.text('3').first);
    await tester.pumpAndSettle();

    expect(find.byType(NumericKeyboard), findsOneWidget);
  });
}
