# Usage guide

How to integrate **flutter_onscreen_keyboard** in a production app (including **GetX**, **TextFormField**, and your own `CustomTextFormField`).

For file-level internals see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Table of contents

1. [Install](#1-install)
2. [Quick start (minimal)](#2-quick-start-minimal)
3. [Integration patterns](#3-integration-patterns)
4. [GetX + ResponsiveBreakpoints](#4-getx--responsivebreakpoints)
5. [Custom TextFormField (your own widget)](#5-custom-textformfield-your-own-widget)
6. [OnscreenTextFormField](#6-onscreentextformfield)
7. [Per-screen host (OnscreenKeyboardHost)](#7-per-screen-host-onscreenkeyboardhost)
8. [Keyboard colors & themes](#8-keyboard-colors--themes)
9. [Attachment flags (kiosk vs forms)](#9-attachment-flags-kiosk-vs-forms)
10. [Validation & rules](#10-validation--rules)
11. [Troubleshooting](#11-troubleshooting)
12. [API cheat sheet](#12-api-cheat-sheet)

---

## 1. Install

In your app `pubspec.yaml`:

```yaml
dependencies:
  flutter_onscreen_keyboard:
    path: ../flutter_onscreen_keyboard
    # or git / pub.dev when published
```

```bash
flutter pub get
```

Single import for the public API:

```dart
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
```

---

## 2. Quick start (minimal)

```dart
void main() {
  FlutterOnscreenKeyboard.configure(
    const OnscreenKeyboardConfig(useCustomKeyboard: true),
  );
  runApp(const OnscreenKeyboardBinding(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => OnscreenKeyboardAttachment(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const MyHomePage(),
    );
  }
}
```

Use `OnscreenTextField` on a screen wrapped with `OnscreenKeyboardHost`, **or** use plain / custom `TextFormField` with `OnscreenKeyboardAttachment` in `MaterialApp.builder` (see below).

---

## 3. Integration patterns

| Pattern | Where to install | Input widget | Best for |
|--------|------------------|--------------|----------|
| **A. App-wide attachment** | `MaterialApp.builder` / `GetMaterialApp.builder` | Any `TextField` / `TextFormField` / your wrapper | Large apps, GetX, existing forms |
| **B. Per-screen host** | Wrap one screen with `OnscreenKeyboardHost` | `OnscreenTextField` (requires `FocusNode`) | Single kiosk screen, max control |

**Do not** combine `KeyboardDismissOnTap` (whole app) with this plugin — it unfocuses fields and fights the custom keyboard. Use `OnscreenKeyboardAttachment` flags instead (`dismissOnTapOutside`, etc.).

**Do not** wrap the same field with both `OnscreenKeyboardHost` tap handling and attachment for the same focus session — pick one pattern per screen.

---

## 4. GetX + ResponsiveBreakpoints

Typical kiosk / industrial app `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Your keyboard palette (see §8)
import 'app_keyboard_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // ① Configure before runApp
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: AppKeyboardTheme.dark,
      useCustomKeyboard: true,
    ),
  );

  // … your existing init (GetStorage, DB, services, etc.)
  await GetStorage.init();
  Get.put(AlarmCon(), permanent: true);

  runApp(
    // ② Theme scope for keyboard widgets
    OnscreenKeyboardBinding(
      child: UserActivityDetector(
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: AppPages.SPLASH,
          getPages: AppPages.routes,
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getTheme(),
          themeMode: Utility.themeMode(),
          transitionDuration: Duration.zero,
          builder: (context, child) {
            return ResponsiveBreakpoints.builder(
              // ③ Replaces KeyboardDismissOnTap
              child: OnscreenKeyboardAttachment(
                commitOnEnterOnly: true,
                lockContentWhileKeyboardVisible: true,
                dismissOnTapOutside: false,
                dismissOnSystemBack: false,
                useDraggableInLandscape: true,
                child: child ?? const SizedBox.shrink(),
              ),
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
              useShortestSide: true,
            );
          },
        ),
      ),
    ),
  );
}
```

### What each wrapper does

| Widget | Role |
|--------|------|
| `FlutterOnscreenKeyboard.configure` | Enables custom keyboard; sets default colors |
| `OnscreenKeyboardBinding` | Provides `ThemeController` via `OnscreenKeyboardThemeScope` |
| `OnscreenKeyboardAttachment` | Blocks system IME; shows keyboard panel; optional content lock |

---

## 5. Custom TextFormField (your own widget)

Keep your existing UI (gradient box, fixed width/height, app colors). Wrap the inner `TextFormField` with **`OnscreenKeyboardFormFieldScope`**.

Reference implementation: [`demo/lib/custom_text_form_field.dart`](../demo/lib/custom_text_form_field.dart).

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.initialValue,
    this.controller,
    this.enabled = true,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.width = 200,
    this.height = 40,
    this.hintText,
    this.decoration,
    this.obscureText = false,
    this.margin,
    this.textAlign,
    // Keyboard rules (same as OnscreenTextField):
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.allowDecimalInput,
    this.integersOnly,
    this.maxFractionDigits,
  });

  final String? initialValue;
  final TextEditingController? controller;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final double width;
  final double height;
  final String? hintText;
  final InputDecoration? decoration;
  final bool obscureText;
  final EdgeInsetsGeometry? margin;
  final TextAlign? textAlign;

  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final bool? allowDecimalInput;
  final bool? integersOnly;
  final int? maxFractionDigits;

  @override
  Widget build(BuildContext context) {
    return OnscreenKeyboardFormFieldScope(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      minLength: minLength,
      maxLength: maxLength,
      minValue: minValue,
      maxValue: maxValue,
      allowDecimalInput: allowDecimalInput,
      integersOnly: integersOnly,
      maxFractionDigits: maxFractionDigits,
      validator: validator,
      builder: (context, handle) {
        return Container(
          height: height,
          width: width,
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.colorTextField, AppColors.colorTextField],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.08, 0.8],
            ),
          ),
          child: TextFormField(
            textAlign: textAlign ?? TextAlign.start,
            controller: handle.controller,
            focusNode: handle.focusNode,
            readOnly: handle.readOnly,
            enabled: enabled,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            cursorColor: AppColors.colorErrorSnackBar,
            obscureText: obscureText,
            cursorHeight: 14,
            maxLength: maxLength,
            style: TextStyle(
              fontSize: Fonts.font_14,
              color: enabled ? AppColors.colorText : AppColors.coloGreyText,
            ),
            decoration: decoration,
            onChanged: onChanged,
            validator: validator,
          ),
        );
      },
    );
  }
}
```

### Important details

- Pass **`handle.controller`**, **`handle.focusNode`**, and **`handle.readOnly`** into your `TextFormField`.
- Do **not** set `initialValue` on `TextFormField` when using a controller — the scope copies `initialValue` into `controller.text` when the controller is empty.
- Optional `controller`: if omitted, the scope creates and disposes one for you.
- With **attachment** mode, `readOnly` is usually `false` (normal focus + system bridge).
- With **host** mode, `readOnly` is `true` and taps open the keyboard via gesture (avoids scroll jump).

Example usage on a screen:

```dart
CustomTextFormField(
  controller: nameController,
  width: 200,
  height: 40,
  minLength: 3,
  maxLength: 24,
  validator: (v) => (v == null || v.length < 3) ? 'Too short' : null,
)
```

No manual `OnscreenKeyboardFieldRules.register` is required when using the scope.

---

## 6. OnscreenTextFormField

Drop-in `TextFormField` with the same keyboard rules. Optional `wrapper` for chrome:

```dart
OnscreenTextFormField(
  controller: controller,
  minLength: 3,
  maxLength: 24,
  decoration: const InputDecoration(labelText: 'Name'),
  validator: (v) => ...,
  wrapper: (context, field) => Container(
    height: 40,
    decoration: BoxDecoration(/* gradient */),
    child: field,
  ),
)
```

Use this if you do not need a separate `CustomTextFormField` class.

---

## 7. Per-screen host (OnscreenKeyboardHost)

Best when you want kiosk behavior on one screen (block other fields, tap-to-open without IME scroll jump):

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnscreenKeyboardHost(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OnscreenTextField(
          controller: _controller,
          focusNode: _focus,
          minLength: 3,
          maxLength: 24,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
```

With **host**, you do **not** need `OnscreenKeyboardAttachment` on that screen (attachment is still fine app-wide for other routes using `TextFormField`).

---

## 8. Keyboard colors & themes

Define colors once:

```dart
class AppKeyboardTheme {
  AppKeyboardTheme._();

  static const OnscreenKeyboardColors light = OnscreenKeyboardColors(
    background: Color(0xFFE8E8E8),
    keyBackground: Color(0xFFFFFFFF),
    keyText: Color(0xFF1A1A1A),
    specialKeyBackground: Color(0xFFD0D0D0),
    specialKeyText: Color(0xFF1A1A1A),
    activeKey: Color(0xFF5C6BC0),
  );

  static const OnscreenKeyboardColors dark = OnscreenKeyboardColors(
    background: Color(0xFF1E1E2C),
    keyBackground: Color(0xFF2A2A3D),
    keyText: Color(0xFFFFFFFF),
    specialKeyBackground: Color(0xFF3D3D56),
    specialKeyText: Color(0xFF00E5D4),
    activeKey: Color(0xFF5C6BC0),
  );
}
```

Configure in `main()`:

```dart
FlutterOnscreenKeyboard.configure(
  OnscreenKeyboardConfig.withColors(
    colors: AppKeyboardTheme.dark,
    useCustomKeyboard: true,
  ),
);
```

Sync with app light/dark mode:

```dart
final isDark = Get.isDarkMode; // or Utility.themeMode()
FlutterOnscreenKeyboard.themeController.applyKeyboardColors(
  isDark ? AppKeyboardTheme.dark : AppKeyboardTheme.light,
  isDarkMode: isDark,
);
```

See [`demo/lib/app_keyboard_theme.dart`](../demo/lib/app_keyboard_theme.dart) for a full preset example (gradients, preview strip, pressed state).

---

## 9. Attachment flags (kiosk vs forms)

| Flag | Kiosk / industrial | Normal data entry |
|------|--------------------|---------------------|
| `commitOnEnterOnly` | `true` — preview strip until Enter | `false` — live typing in field |
| `lockContentWhileKeyboardVisible` | `true` | `true` or `false` |
| `dismissOnTapOutside` | `false` — close with **X** only | `true` |
| `dismissOnSystemBack` | `false` | `true` |
| `useDraggableInLandscape` | `true` (default) | `true` |

---

## 10. Validation & rules

Rules are declared on the field (or scope):

| Parameter | Effect |
|-----------|--------|
| `minLength` / `maxLength` | Alpha keyboard length |
| `minValue` / `maxValue` | Numeric range |
| `integersOnly` | No decimal key |
| `maxFractionDigits` | Cap digits after `.` |
| `validator` | Custom message; runs on keyboard + optional `Form` |

Helpers:

```dart
OnscreenKeyboardValidators.email(value)
```

Live validation on the keyboard preview matches numeric behavior after the first keystroke.

---

## 11. Troubleshooting

| Symptom | Fix |
|---------|-----|
| System keyboard still opens | `useCustomKeyboard: true`, `OnscreenKeyboardBinding` + `OnscreenKeyboardAttachment` in `builder` |
| Keyboard never opens | Same as above; field must be focusable (`enabled: true`) |
| Tap dismisses keyboard / field blurs | Remove app-wide `KeyboardDismissOnTap` |
| Form jumps when keyboard opens | Use `OnscreenKeyboardHost` + `OnscreenTextField`, or scope with `readOnly` + gesture (host path) |
| Rules ignored on `TextFormField` | Wrap with `OnscreenKeyboardFormFieldScope` or use `OnscreenTextFormField` |
| Theme does not update | Call `themeController.applyKeyboardColors` / `updateTheme`; check `lockKeyboardTheme` in config |
| `setState() after dispose` on keys | Upgrade to latest plugin (key animations guard `mounted`) |

---

## 12. API cheat sheet

```dart
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

// Init
FlutterOnscreenKeyboard.configure(OnscreenKeyboardConfig(...));
OnscreenKeyboardBinding(child: ...)
OnscreenKeyboardAttachment(child: ...)   // MaterialApp.builder

// Fields
OnscreenTextField(...)                   // + OnscreenKeyboardHost
OnscreenTextFormField(...)               // TextFormField + rules
OnscreenKeyboardFormFieldScope(...)      // your CustomTextFormField

// Manual rules (only if not using scope / OnscreenTextFormField)
OnscreenKeyboardFieldRules.register(focusNode, OnscreenFieldRule(...));
OnscreenKeyboardFieldRules.unregister(focusNode);

// Theme
FlutterOnscreenKeyboard.themeController
OnscreenKeyboardColors(...)
OnscreenKeyboardConfig.withColors(colors: ...)
```

---

## Demo app

Run the included demo:

```bash
cd demo && flutter run
```

- [`demo/lib/main.dart`](../demo/lib/main.dart) — `OnscreenKeyboardAttachment` + `OnscreenTextFormField`
- [`demo/lib/custom_text_form_field.dart`](../demo/lib/custom_text_form_field.dart) — custom wrapper pattern
