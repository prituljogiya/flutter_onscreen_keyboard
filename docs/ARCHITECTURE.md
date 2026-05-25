# Architecture — flutter_onscreen_keyboard

This document is a single-page reference for the package's source layout: what every file is responsible for, how the pieces fit together, and what you import for each common task.

- [Quick start](#quick-start)
- [Top-level structure](#top-level-structure)
- [Public entry point](#public-entry-point)
- [Library layout (`lib/`)](#library-layout-lib)
  - [`lib/app/` — optional runnable shell](#libapp--optional-runnable-shell)
  - [`lib/core/` — state, validation, theming, utilities](#libcore--state-validation-theming-utilities)
  - [`lib/widgets/` — UI widgets](#libwidgets--ui-widgets)
- [Data flow at a glance](#data-flow-at-a-glance)
- [How to use the package](#how-to-use-the-package)
  - [1. Configure once in `main()`](#1-configure-once-in-main)
  - [2. Wrap your screen with `OnscreenKeyboardHost`](#2-wrap-your-screen-with-onscreenkeyboardhost)
  - [3. Use `OnscreenTextField` for inputs](#3-use-onscreentextfield-for-inputs)
  - [4. Configure validation per field](#4-configure-validation-per-field)
- [Adding new behaviour — recipes](#adding-new-behaviour--recipes)
- [Naming conventions](#naming-conventions)

---

## Quick start

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
        body: OnscreenKeyboardHost(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OnscreenTextField(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          ),
        ),
      ),
    );
  }
}
```

Three things to remember:

1. `FlutterOnscreenKeyboard.configure(...)` (or `OnscreenKeyboardBinding`) in `main()` initialises the shared theme controller.
2. Every screen that needs the on-screen keyboard wraps its scrollable form in **`OnscreenKeyboardHost`**.
3. Every field that should trigger the on-screen keyboard is an **`OnscreenTextField`** (regular `TextField` still uses the system keyboard).

---

## Top-level structure

```
flutter_onscreen_keyboard/
├── lib/
│   ├── custom_keyboard.dart                  ← public library entry
│   ├── flutter_onscreen_keyboard_init.dart   ← static init API + bindings
│   ├── app/                                  ← optional standalone shell
│   ├── core/                                 ← state, validation, theming, utilities
│   └── widgets/                              ← UI widgets (fields, panels, keys)
├── docs/
│   ├── ARCHITECTURE.md                       ← this file
│   └── TEST_CASES.md                         ← test catalog
├── test/                                     ← package unit tests
└── example/                                  ← demo Flutter app
```

---

## Public entry point

### `lib/custom_keyboard.dart`

The single import surface of the package. Re-exports everything an app needs:

| Re-exported from | What it gives you |
|---|---|
| `flutter_onscreen_keyboard_init.dart` | `FlutterOnscreenKeyboard`, `OnscreenKeyboardBinding`, `OnscreenKeyboardThemeScope` |
| `app/custom_keyboard_app.dart` | `CustomKeyboardApp` (optional runnable shell) |
| `core/onscreen_keyboard_config.dart` | `OnscreenKeyboardConfig`, `globalOnscreenKeyboardConfig`, `useCustomOnscreenKeyboard` |
| `core/onscreen_keyboard_colors.dart` | `OnscreenKeyboardColors` (palette) |
| `core/theme_controller.dart` | `ThemeController`, `KeyboardTheme` |
| `core/keyboard_theme_resolver.dart` | `resolveKeyboardTheme`, `buildKeyboardWithResolvedTheme` |
| `core/keyboard_controller.dart` | `KeyboardController` (alpha keyboard state) |
| `core/numeric_keyboard_controller.dart` | `NumericKeyboardController` (numeric keyboard state) |
| `core/numeric_range.dart` | `NumericRange` (min/max + digit validation helpers) |
| `core/onscreen_keyboard_validation.dart` | `OnscreenKeyboardValidators` (`email`, etc.) |
| `core/onscreen_keyboard_mapping.dart` | `preferOnscreenNumericKeyboard`, `integersOnlyKeyboardType` |
| `widgets/onscreen_keyboard_host.dart` | `OnscreenKeyboardHost`, `OnscreenKeyboardScope` |
| `widgets/onscreen_text_field.dart` | `OnscreenTextField` |
| `widgets/onscreen_field_session.dart` | `OnscreenFieldSession` |
| `widgets/custom_keyboard.dart` | `CustomKeyboard` (alpha keyboard widget) |
| `widgets/numeric.dart` | `NumericKeyboard` (numeric keyboard widget) |
| `widgets/draggable.dart` | `DraggableDynamicKeyboard` (landscape draggable wrapper) |
| `widgets/keyboard_key.dart`, `widgets/dual_key.dart`, `widgets/numeric_keyboard_key.dart` | Individual key widgets |

Only `custom_keyboard.dart` is intended to be imported from app code; everything else under `lib/` is implementation detail and may evolve.

### `lib/flutter_onscreen_keyboard_init.dart`

Three exports:

- **`FlutterOnscreenKeyboard`** — abstract final static class. Single source of truth for runtime config:
  - `configure(OnscreenKeyboardConfig)` — call once in `main()` before `runApp`.
  - `ensureInitialized()` — idempotent, safe to call repeatedly.
  - `themeController` — process-wide `ThemeController` (lazy-created).
  - `config`, `useCustomKeyboard` — read current config flags.
  - `resetForTest()` — disposes the controller and resets global config (test-only).
- **`OnscreenKeyboardBinding`** — wrap your `MaterialApp` (or app root) with this so the plugin registers its dependencies. It also installs the `OnscreenKeyboardThemeScope`.
- **`OnscreenKeyboardThemeScope`** — `InheritedNotifier<ThemeController>` that lets descendant keyboard widgets rebuild when the theme changes (no GetX).

---

## Library layout (`lib/`)

### `lib/app/` — optional runnable shell

#### `app/custom_keyboard_app.dart`
`CustomKeyboardApp` — a minimal `StatelessWidget` that creates a `MaterialApp` (with light/dark themes from `ThemeController`) and installs `OnscreenKeyboardBinding`. Useful for demos / sample apps; not needed if you already have a `MaterialApp` in your app.

### `lib/core/` — state, validation, theming, utilities

#### `core/keyboard_controller.dart`
`KeyboardController extends ChangeNotifier`. Drives the alpha (QWERTY) keyboard:

- Text manipulation: `insertText`, `backspace`, `insertSpace`, `clear`, `moveCursor`, `enter`.
- Shift / caps state: `toggleShift`, `onCapsKeyPressed`, `isShiftActive`, `isCapsLock`, `isCapsOneShot`, `useTopCharacterOnDualKey`.
- Length / validator: `minLength`, `maxLength`, `validator`, `clearValidation`.
- Lifecycle: `dispose()`.

Owned by `CustomKeyboard`'s `State`; one instance per active alpha keyboard.

#### `core/numeric_keyboard_controller.dart`
`NumericKeyboardController extends ChangeNotifier`. Drives the numeric keypad:

- Input: `insertDigit`, `insertDecimal`, `backspace`, `clear`, `enter`.
- Range/format: `minValue`, `maxValue`, `integersOnly`, `allowDecimalInput`, `maxLength`.
- Validation: `_validate` runs after each edit (deferred while typing a `.` ending, suppressed before first user edit).
- `rebind(...)` — reuses a single controller across field switches.

Owned by `NumericKeyboard`'s `State`.

#### `core/theme_controller.dart`
`ThemeController extends ChangeNotifier` + the `KeyboardTheme` data class. Manages:

- App-level `ThemeData` (`lightTheme`, `darkTheme`, `themeMode`).
- Per-keyboard `keyboardTheme` (key colors, border, gradients, special-key tint, etc.).
- Built-in palettes via factory constructors on `KeyboardTheme` (e.g. `KeyboardTheme.purpleCyan()`).

A single instance is created lazily through `FlutterOnscreenKeyboard.themeController`.

#### `core/keyboard_theme_resolver.dart`
Two helpers used by every keyboard widget:

- `resolveKeyboardTheme(...)` — priority: explicit widget override → global config → scoped `ThemeController` → singleton `ThemeController`.
- `buildKeyboardWithResolvedTheme(...)` — wraps the keyboard subtree in a `ListenableBuilder` when the theme is not fixed, so palette changes repaint live.

#### `core/onscreen_keyboard_config.dart`
`OnscreenKeyboardConfig` — immutable config object passed to `FlutterOnscreenKeyboard.configure`:

- `useCustomKeyboard` — toggle between custom on-screen keyboard and the system IME.
- `keyboardTheme`, `replaceDefaultTheme` — provide a fixed theme or override the controller's default.

The global mutable state lives in two free functions: `globalOnscreenKeyboardConfig` (getter) and `setGlobalOnscreenKeyboardConfig`. The bool helper `useCustomOnscreenKeyboard` short-circuits to system keyboard everywhere when false.

#### `core/onscreen_keyboard_colors.dart`
`OnscreenKeyboardColors` — opinionated palette object that `KeyboardTheme.fromColors` consumes. Keep all your brand colors here.

#### `core/onscreen_keyboard_mapping.dart`
Functions to convert a `TextInputType` into "which on-screen keyboard?":

- `preferOnscreenNumericKeyboard(type)` — true for `TextInputType.number`, `phone`, decimal/signed variants.
- `integersOnlyKeyboardType(type)` — true for `TextInputType.number` without `decimal: true`.
- `allowsDecimalInput(type)` — kept for legacy callers.

#### `core/numeric_range.dart`
`NumericRange` (abstract final). Pure helpers for the numeric keypad's input rules and validation:

- `validate(value, min, max, integersOnly, allowIncomplete)` — full validation (used by both live validation while typing and strict validation on Enter).
- `canAcceptDigit(...)` — predicate the keypad calls before mutating text. Rejects keystrokes that would exceed `maxLength`, the implied whole/fractional digit count, or the numeric `max` (the latter is what stops you typing `999` in a 1–200 field).
- `commitText(...)` — normalises staging text on commit (e.g. `10.0` → `10` for integer fields).
- `formatBound`, `wholeNumberDigitsForRange`, `fractionalDigitsForRange`, `isIncompleteDecimal` — small helpers used by the keypad UI labels.

#### `core/onscreen_keyboard_validation.dart`
`OnscreenKeyboardValidators` (abstract final). Reusable validator functions you can plug into `OnscreenTextField.validator`:

- `OnscreenKeyboardValidators.email(value)` — RFC-ish email check.

Add more reusable validators here.

#### `core/keyboard_chrome_layout.dart`
`KeyboardChromeLayout` — layout math for the numeric panel's height (different rows show / hide based on whether bounds + errors are visible).

#### `core/keyboard_key_timing.dart`
Centralised animation durations (`pressAnimation`, etc.) so every key uses the same timing.

#### `core/preview_strip_scroll.dart`
Helper to keep the keyboard's preview text strip auto-scrolled to the caret as the user types.

#### `core/text_editing_controller_guard.dart`
Helper `isTextEditingControllerUsable(controller)` — defensive check before mutating a controller (e.g. it might already be disposed when a field switch races).

### `lib/widgets/` — UI widgets

#### `widgets/onscreen_keyboard_host.dart`
`OnscreenKeyboardHost` — **the most important widget for app code**. Wrap your form (or whole screen body) in it.

Responsibilities:

- Tracks the active `OnscreenFieldSession` (`_session`) and rebuilds when it changes.
- Mounts the right keyboard widget (`CustomKeyboard` or `NumericKeyboard`) when a session opens.
- In landscape, wraps in `DraggableDynamicKeyboard`; in portrait, uses an `AnimatedSize`-wrapped slot below the form.
- Keeps the form widget element stable across keyboard open/close via a `GlobalKey` (`_formAnchorKey`) — otherwise the `Scrollable` would be disposed and the user's scroll offset would snap to 0.
- Captures + restores the form's scroll offset around open/close (`_pinScrollOffset`, `_restoreHostScrollAfterDismiss`).
- Static API used by `OnscreenTextField`: `activate(context, session)`, `dismiss(context)`, `isOpen(context)`, `isOpenFor(context, focusNode)`.
- Exposes `OnscreenKeyboardScope` — inherited widget that lets descendants (`OnscreenTextField`) know whether the keyboard is open and for which `FocusNode`.

#### `widgets/onscreen_text_field.dart`
`OnscreenTextField` — drop-in replacement for `TextField` that triggers the on-screen keyboard.

Key implementation details:

- The internal `TextField` is wrapped in **`AbsorbPointer`** and an outer `GestureDetector` handles the tap. This prevents `TextField` from focusing itself on tap (which would call `EditableText._showCaretOnScreen` and cause the surrounding `Scrollable` to jump).
- When `useCustomOnscreenKeyboard` is false it returns a plain `TextField` with the system keyboard.
- `_syncFocusPolicy` flips `canRequestFocus` to false on all *other* fields while one keyboard session is active, so the user can't escape to another field without dismissing.

#### `widgets/onscreen_field_session.dart`
`OnscreenFieldSession` — immutable bundle of everything a field hands to the host when it activates: `controller`, `focusNode`, `keyboardType`, `min/maxLength`, `min/maxValue`, `validator`, decimal/integer flags. The host stores one in `_session` and forwards relevant pieces to the keyboard widget.

#### `widgets/custom_keyboard.dart`
`CustomKeyboard` — the alpha (QWERTY + numeric overlay) keyboard widget.

- Renders the preview text strip (with its own `_previewFocusNode` and `_previewScrollController`).
- Owns a `KeyboardController` (one per mount).
- `_grabPreviewFocus()` takes preview focus on mount and on host-field switch (since the host field is never focused — see `onscreen_text_field.dart`).
- Composes `KeyboardKey` and `DualKey` rows.
- Wraps the preview commit in `commitOnEnterOnly` semantics — the user's `TextEditingController` is only mutated on Enter (unless the caller opts out).

#### `widgets/numeric.dart`
`NumericKeyboard` — the numeric keypad.

- Same pattern as `CustomKeyboard`, but with `NumericKeyboardController` and `NumericKey` keys.
- Shows the min/max bounds row when both are configured and a validation-error row when an error is active.
- Lays out 0–9, `.`, backspace, clear, Enter in a 3×4 + side-rail grid.

#### `widgets/draggable.dart`
`DraggableDynamicKeyboard` — landscape wrapper that puts the keyboard panel in a `Positioned` overlay on top of the form. The panel:

- Centres on first layout (via the `LayoutBuilder` builder, synchronously, so it never paints at the wrong offset).
- Tracks a `_position` `ValueNotifier<Offset>` for fast pan updates without rebuilding the form below.
- Wraps the panel in `_AnimatedKeyboardAppearance` for a fade + slight scale-in on first mount.

#### `widgets/dual_key.dart`
`DualKey` — two-glyph key (e.g. `q | 1`). Tapping it inserts the bottom character normally and the top character when Shift / Caps is active (driven by `KeyboardController.useTopCharacterOnDualKey`). Long-press for special characters is intentionally disabled; the alternate-character `OverlayEntry` infrastructure is still present for a future "hold key → accent picker" feature.

#### `widgets/keyboard_key.dart`
`KeyboardKey` — the generic alphabetic / special key used everywhere in `CustomKeyboard`. Renders the press animation, theme-aware background, optional icon child, etc.

#### `widgets/numeric_keyboard_key.dart`
`NumericKey` — same role as `KeyboardKey` but tuned for the numeric pad (rectangular, larger glyph, no Shift state).

#### `widgets/keyboard_tap_target.dart`
`KeyboardTapTarget` — low-level press/release gesture handler that both key widgets share. Exposes `onPressed`, `onLongPress`, `onPointerStateChanged`, and a `fireOnRelease` flag (used when alternate-char overlay handling needs to defer the primary key insertion).

---

## Data flow at a glance

```
                        ┌────────────────────────────────────────────────┐
                        │  FlutterOnscreenKeyboard.configure(config)     │
                        │  (lib/flutter_onscreen_keyboard_init.dart)     │
                        └────────────────────────────────────────────────┘
                                          │
                                          ▼
                        ┌────────────────────────────────────────────────┐
                        │  OnscreenKeyboardBinding                       │
                        │  └─ OnscreenKeyboardThemeScope (InheritedNot.)│
                        │     └─ MaterialApp                            │
                        └────────────────────────────────────────────────┘
                                          │
                                          ▼
                        ┌────────────────────────────────────────────────┐
                        │  Your screen                                   │
                        │  └─ OnscreenKeyboardHost                       │
                        │     └─ OnscreenKeyboardScope (inherited)      │
                        │        └─ Your form                            │
                        │           └─ OnscreenTextField (n times)       │
                        └────────────────────────────────────────────────┘
                                          │ tap
                                          ▼
       ┌─────────────────────────────────────────────────────────────────┐
       │  OnscreenTextField.onTap                                        │
       │   → OnscreenKeyboardHost.activate(context, OnscreenFieldSession)│
       │     → setState(_session = session)                              │
       │       → builds CustomKeyboard or NumericKeyboard                │
       │         └─ owns KeyboardController / NumericKeyboardController  │
       └─────────────────────────────────────────────────────────────────┘
                                          │ keystrokes
                                          ▼
       ┌─────────────────────────────────────────────────────────────────┐
       │  KeyboardController / NumericKeyboardController                 │
       │   - mutates the keyboard's internal staging TextEditingController│
       │   - NumericRange.canAcceptDigit gates each digit                │
       │   - validator runs after every edit (live error)                │
       │   - on Enter: commits staging text to widget.controller         │
       │              + calls onEnterPressed / onSubmitted               │
       │              + asks OnscreenKeyboardHost to dismiss             │
       └─────────────────────────────────────────────────────────────────┘
```

---

## How to use the package

### 1. Configure once in `main()`

```dart
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

void main() {
  FlutterOnscreenKeyboard.configure(
    const OnscreenKeyboardConfig(
      useCustomKeyboard: true,                       // false → system IME everywhere
      keyboardTheme: KeyboardTheme.purpleCyan(),     // optional fixed theme
      replaceDefaultTheme: true,
    ),
  );
  runApp(const OnscreenKeyboardBinding(child: MyApp()));
}
```

You can also use `CustomKeyboardApp` instead of writing your own `MaterialApp`:

```dart
runApp(CustomKeyboardApp(child: MyHomePage()));
```

### 2. Wrap your screen with `OnscreenKeyboardHost`

```dart
Scaffold(
  body: OnscreenKeyboardHost(
    commitOnEnterOnly: true,  // text commits to your controller only on Enter
    useDraggableInLandscape: true,
    child: SingleChildScrollView(
      child: Column(
        children: [
          OnscreenTextField(controller: c1, focusNode: f1, decoration: ...),
          OnscreenTextField(controller: c2, focusNode: f2, decoration: ...),
        ],
      ),
    ),
  ),
)
```

The host listens to its children's taps and shows the appropriate keyboard automatically.

### 3. Use `OnscreenTextField` for inputs

```dart
OnscreenTextField(
  controller: _emailController,
  focusNode: _emailFocus,
  keyboardType: TextInputType.emailAddress,
  validator: OnscreenKeyboardValidators.email,
  decoration: const InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
  ),
),
```

The keyboard type chooses the panel:

| `keyboardType` | Panel | Notes |
|---|---|---|
| `TextInputType.text` (default) | Alpha QWERTY | |
| `TextInputType.emailAddress` | Alpha QWERTY | |
| `TextInputType.multiline` | Alpha QWERTY | |
| `TextInputType.number` | Numeric pad | Integers only |
| `TextInputType.numberWithOptions(decimal: true)` | Numeric pad | `.` key enabled |
| `TextInputType.phone` | Numeric pad | No min/max labels |

### 4. Configure validation per field

| Goal | Use |
|---|---|
| Length bounds (alpha) | `minLength: 3, maxLength: 24` |
| Integer range | `minValue: 18, maxValue: 60` + `keyboardType: TextInputType.number` |
| Decimal range | `minValue: 0.5, maxValue: 500` + `keyboardType: numberWithOptions(decimal: true)` |
| Custom rule on Enter | `validator: (value) => myCheck(value)` |
| Force whole numbers even if decimal panel is shown | `integersOnly: true` |
| Hide the `.` key | `allowDecimalInput: false` |
| Exact length (e.g. PIN) | `maxLength: 4` |
| Cap fractional digits (e.g. `0.12` ok, `0.123` rejected) | `maxFractionDigits: 2` |

The numeric pad rejects keystrokes that would exceed `maxValue` even before `validator` runs — see `NumericRange.canAcceptDigit`.

> **Fractional digits are unlimited by default.** `minValue` / `maxValue` only enforce the numeric value — they do **not** impose any implicit cap on how many digits the user can type after `.`. So a `0.5–500` weight field happily accepts `0.123456789` (still ≤ 500). To cap fractional length, opt in with `maxFractionDigits`:
>
> ```dart
> OnscreenTextField(
>   controller: c,
>   focusNode: f,
>   keyboardType: const TextInputType.numberWithOptions(decimal: true),
>   minValue: 0.5,
>   maxValue: 500,
>   maxFractionDigits: 2, // typing "0.12" works, "0.123" is rejected
> )
> ```

---

## Adding new behaviour — recipes

### Add a new reusable validator
`lib/core/onscreen_keyboard_validation.dart` → add a static method on `OnscreenKeyboardValidators`. It must return `String?` (null = valid).

### Add a new built-in theme palette
`lib/core/theme_controller.dart` → add a factory constructor on `KeyboardTheme` (e.g. `KeyboardTheme.ocean()`), populating the relevant color and border fields.

### Change the alpha keyboard layout
`lib/widgets/custom_keyboard.dart` → modify the row definitions in `_buildAlphaKeyboard` / `_buildNumericLayer` and reuse `_buildKey` for new keys.

### Change which keystrokes the numeric pad rejects
`lib/core/numeric_range.dart` → adjust `canAcceptDigit`. There is a dedicated suite in `test/numeric_range_test.dart`.

### Add a brand-new keyboard panel (e.g. emoji)
1. New widget in `lib/widgets/emoji_keyboard.dart` with its own `ChangeNotifier` controller in `lib/core/emoji_keyboard_controller.dart`.
2. Extend `OnscreenFieldSession` with a flag (e.g. `useEmojiKeyboard`).
3. In `OnscreenKeyboardHost._buildActiveKeyboard`, branch on the new flag.
4. Re-export both new files from `lib/custom_keyboard.dart`.

---

## Naming conventions

- **Files**: `lower_case_with_underscores.dart`. The four previously camelCased files (`numericKeyController`, `duelKey`, `keyboardkey`, `numericKeyboardKey`) have been renamed to follow this convention.
- **Classes**: `UpperCamelCase`. Where a file's class name doesn't match the snake-cased filename (e.g. `widgets/dual_key.dart` exports `DualKey`), they are listed in the table above.
- **Free functions and top-level fields**: `lowerCamelCase`. The few we expose (`useCustomOnscreenKeyboard`, `globalOnscreenKeyboardConfig`, `preferOnscreenNumericKeyboard`) are intentionally short because they appear in app config.
- **Test files**: mirror the file under test, with `_test.dart` suffix.
