# flutter_onscreen_keyboard

A drop-in **custom on-screen keyboard** for Flutter (alpha + numeric) that you can use *instead of* the system IME. Designed for kiosks, POS, tablets, embedded Linux, and any app that needs a fully controlled keyboard.

- Pure Flutter — no GetX, no service locator. State via `ChangeNotifier`.
- Decoupled from your input widget — use `OnscreenTextField` or wire it to your own controller.
- Alpha (QWERTY + numeric overlay) **and** numeric pad with min/max range, decimal cap, `maxLength`, custom validators.
- Themeable via `KeyboardTheme` / `OnscreenKeyboardColors`.
- Draggable in landscape, slides up in portrait, with smooth open/close animations.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full file-by-file reference, and [`docs/TEST_CASES.md`](docs/TEST_CASES.md) for the test catalog.

---

## 1. Install

Add the dependency to your app's `pubspec.yaml` (path or git — until it's published to pub.dev):

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_onscreen_keyboard:
    path: ../flutter_onscreen_keyboard
  # or:
  # flutter_onscreen_keyboard:
  #   git:
  #     url: https://github.com/<you>/flutter_onscreen_keyboard.git
  #     ref: main
```

Then run:

```bash
flutter pub get
```

---

## 2. Configure once in `main()`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

void main() {
  FlutterOnscreenKeyboard.configure(
    const OnscreenKeyboardConfig(useCustomKeyboard: true),
  );
  runApp(const OnscreenKeyboardBinding(child: MyApp()));
}
```

- `useCustomKeyboard: false` falls back to the system IME everywhere (no other code change needed).
- `OnscreenKeyboardBinding` installs the shared theme controller for the keyboard widgets.

---

## 3. Minimal working app

The smallest possible integration: one screen, one field. Drop this in `lib/main.dart` and run.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

void main() {
  FlutterOnscreenKeyboard.configure(
    const OnscreenKeyboardConfig(useCustomKeyboard: true),
  );
  runApp(const OnscreenKeyboardBinding(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('On-screen keyboard demo')),
        body: const _Form(),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form();
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnscreenKeyboardHost(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OnscreenTextField(
          controller: _name,
          focusNode: _nameFocus,
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

That's it. Tapping the field opens the custom keyboard; Enter dismisses it.

---

## 4. Common field recipes

```dart
// Alpha field with length bounds.
OnscreenTextField(
  controller: c1, focusNode: f1,
  minLength: 3, maxLength: 24,
  decoration: const InputDecoration(labelText: 'Username'),
)

// Email (validator runs on Enter).
OnscreenTextField(
  controller: c2, focusNode: f2,
  keyboardType: TextInputType.emailAddress,
  validator: OnscreenKeyboardValidators.email,
  decoration: const InputDecoration(labelText: 'Email'),
)

// Integer range (numeric pad, no decimal key).
OnscreenTextField(
  controller: c3, focusNode: f3,
  keyboardType: TextInputType.number,
  minValue: 18, maxValue: 60,
  decoration: const InputDecoration(labelText: 'Age (18–60)'),
)

// Decimal range. Numeric max is enforced (500.1 rejected) but fractional
// digits are NOT capped by the bounds — the user can type 0.123456789.
OnscreenTextField(
  controller: c4, focusNode: f4,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  minValue: 0.5, maxValue: 500,
  decoration: const InputDecoration(labelText: 'Weight kg'),
)

// Same range, but opt into a fractional-digit cap.
OnscreenTextField(
  controller: c5, focusNode: f5,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  minValue: 0.5, maxValue: 500,
  maxFractionDigits: 2, // "0.12" ok, "0.123" rejected
  decoration: const InputDecoration(labelText: 'Price'),
)

// Exact-length PIN.
OnscreenTextField(
  controller: c6, focusNode: f6,
  keyboardType: TextInputType.number,
  maxLength: 4,
  decoration: const InputDecoration(labelText: 'PIN (4 digits)'),
)
```

| Want | Use |
|---|---|
| Length bounds (alpha) | `minLength`, `maxLength` |
| Integer range | `keyboardType: TextInputType.number` + `minValue`/`maxValue` |
| Decimal range | `keyboardType: numberWithOptions(decimal: true)` + `minValue`/`maxValue` |
| Cap fractional digits (opt-in; bounds alone don't cap them) | `maxFractionDigits: 2` |
| Custom rule on Enter | `validator: (v) => myCheck(v)` |
| Phone keypad (no min/max labels) | `keyboardType: TextInputType.phone` |

---

## 5. Theming

Set a palette on `configure`:

```dart
FlutterOnscreenKeyboard.configure(
  const OnscreenKeyboardConfig(
    useCustomKeyboard: true,
    keyboardTheme: KeyboardTheme.purpleCyan(),
    replaceDefaultTheme: true,
  ),
);
```

Or build your own from a flat color object:

```dart
final myTheme = KeyboardTheme.fromColors(const OnscreenKeyboardColors(
  background: Color(0xFF1E1E2A),
  keyBackground: Color(0xFF2A2A39),
  keyText: Colors.white,
  specialKey: Color(0xFF7C4DFF),
  border: Color(0x33FFFFFF),
));
```

You can also flip the palette at runtime:

```dart
FlutterOnscreenKeyboard.themeController.updateTheme(KeyboardTheme.purpleCyan());
```

---

## 6. Turning it off

To use the **system keyboard** without removing any code, just set:

```dart
FlutterOnscreenKeyboard.configure(
  const OnscreenKeyboardConfig(useCustomKeyboard: false),
);
```

`OnscreenTextField` automatically falls back to a plain `TextField` and `OnscreenKeyboardHost` becomes a no-op wrapper.

---

## 7. Public API (cheat sheet)

```dart
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

// Initialisation
FlutterOnscreenKeyboard.configure(OnscreenKeyboardConfig(...));
OnscreenKeyboardBinding(child: ...)            // wrap MaterialApp (or app root)
CustomKeyboardApp(child: ...)                  // optional self-contained MaterialApp shell

// Layout
OnscreenKeyboardHost(child: ...)               // wrap your form / screen
OnscreenTextField(controller, focusNode, ...)  // input field

// Validation helpers
OnscreenKeyboardValidators.email
NumericRange.validate(...)

// Theme
FlutterOnscreenKeyboard.themeController
KeyboardTheme.purpleCyan()
OnscreenKeyboardColors(...)
```

Anything else in `lib/` is implementation detail and may evolve — only import via `package:flutter_onscreen_keyboard/custom_keyboard.dart`.

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Tapping field opens the **system** keyboard | `useCustomKeyboard` is `false` in your config, or you forgot `OnscreenKeyboardBinding` |
| Keyboard opens but the form jumps / blinks on tap | Make sure you used `OnscreenTextField`, not a plain `TextField` (the host relies on it to intercept tap focus) |
| In landscape, keyboard overlaps the field instead of appearing in a draggable panel | That's expected — the panel is draggable. Pan it to where you want; the position is remembered for the session |
| Numeric field accepts unlimited digits after `.` | This is the default. Set `maxFractionDigits: N` on the `OnscreenTextField` to cap it. `minValue` / `maxValue` only constrain the numeric value, not the fractional length. |
| Numeric field lets me type values outside `min/max` | Inside the digit width of `max` it does (e.g. for `max: 500` you can type `555` so you see the "Must be ≤ 500" error). Beyond that width — `5555` for the same field — keystrokes are silently rejected. Enter stays blocked until the value is back in range. |
| Want to switch theme dynamically | Call `FlutterOnscreenKeyboard.themeController.updateTheme(...)` from anywhere |

---

## Status

- ✅ 51 unit/widget tests passing
- ✅ No GetX dependency
- ✅ Works on Android / iOS / desktop / web
- 📁 Architecture reference: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- 📁 Test catalog: [`docs/TEST_CASES.md`](docs/TEST_CASES.md)
