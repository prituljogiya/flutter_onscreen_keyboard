import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:flutter_onscreen_keyboard/core/theme_controller.dart';
import 'package:flutter_onscreen_keyboard/widgets/onscreen_keyboard_host.dart';
import 'package:flutter_onscreen_keyboard/widgets/onscreen_text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    FlutterOnscreenKeyboard.configure(
      const OnscreenKeyboardConfig(useCustomKeyboard: true),
    );
    Get.put(ThemeController());
  });

  tearDown(Get.reset);

  testWidgets('restores scroll offset when keyboard closes', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final textController = TextEditingController();
    addTearDown(textController.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: OnscreenKeyboardHost(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 1800),
                  OnscreenTextField(
                    fieldKey: const ValueKey<String>('field'),
                    controller: textController,
                    focusNode: focusNode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    final offsetBeforeKeyboard = scrollController.offset;
    expect(offsetBeforeKeyboard, greaterThan(100));

    await tester.tap(find.byType(OnscreenTextField));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsWidgets);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(
      scrollController.offset,
      closeTo(offsetBeforeKeyboard, 2.0),
    );
  });
}
