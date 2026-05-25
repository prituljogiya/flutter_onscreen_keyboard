import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterOnscreenKeyboard.resetForTest();
    FlutterOnscreenKeyboard.configure(
      const OnscreenKeyboardConfig(useCustomKeyboard: true),
    );
  });

  tearDown(FlutterOnscreenKeyboard.resetForTest);

  testWidgets('does not switch field until keyboard is closed', (
    WidgetTester tester,
  ) async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final nameFocus = FocusNode();
    final ageFocus = FocusNode();
    addTearDown(nameController.dispose);
    addTearDown(ageController.dispose);
    addTearDown(nameFocus.dispose);
    addTearDown(ageFocus.dispose);

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      OnscreenKeyboardBinding(
        child: MaterialApp(
          home: Scaffold(
            body: OnscreenKeyboardHost(
              child: Column(
                children: [
                  OnscreenTextField(
                    fieldKey: const ValueKey<String>('field_name'),
                    controller: nameController,
                    focusNode: nameFocus,
                  ),
                  OnscreenTextField(
                    fieldKey: const ValueKey<String>('field_age'),
                    controller: ageController,
                    focusNode: ageFocus,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('field_name')));
    await tester.pumpAndSettle();
    expect(find.byType(CustomKeyboard), findsOneWidget);
    expect(find.byType(NumericKeyboard), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('field_age')));
    await tester.pumpAndSettle();
    expect(find.byType(CustomKeyboard), findsOneWidget);
    expect(find.byType(NumericKeyboard), findsNothing);
    expect(ageFocus.hasFocus, isFalse);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('field_age')));
    await tester.pumpAndSettle();
    expect(find.byType(NumericKeyboard), findsOneWidget);
    expect(find.byType(CustomKeyboard), findsNothing);
  });
}
