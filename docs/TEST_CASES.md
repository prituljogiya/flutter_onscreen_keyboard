# Test Cases — flutter_onscreen_keyboard

This document describes every automated test in the package and the example app. Use it for QA handoff, regression planning, and onboarding.

## Summary

| Suite | Location | Type | Test count |
|-------|----------|------|------------|
| KeyboardController | `test/keyboard_controller_test.dart` | Unit | 6 |
| NumericKeyboardController | `test/numeric_keyboard_controller_test.dart` | Unit | 5 |
| NumericRange | `test/numeric_range_test.dart` | Unit | 3 |
| Keyboard mapping | `test/onscreen_keyboard_mapping_test.dart` | Unit | 2 |
| Theme colors | `test/onscreen_keyboard_colors_test.dart` | Unit | 2 |
| Demo smoke | `example/test/widget_test.dart` | Widget | 2 |
| Demo integration | `example/test/all_fields_keyboard_test.dart` | Widget | 18 |
| **Total** | | | **38** |

## How to run

```bash
# Package unit tests (18 tests)
flutter test

# Example widget / integration tests (20 tests)
cd example && flutter test

# Everything
flutter test && cd example && flutter test
```

---

## 1. Package unit tests

### 1.1 `test/keyboard_controller_test.dart`

Tests [KeyboardController](../lib/core/keyboard_controller.dart) in isolation (GetX test mode, no UI).

#### Group: `KeyboardController typing`

| ID | Test name | Preconditions | Steps | Expected result |
|----|-----------|---------------|-------|-----------------|
| KC-01 | `insertText appends and clears shift` | Fresh controller; shift toggled on | Call `insertText('a')` | Text is `a`; shift is off after insert |
| KC-02 | `maxLength stops further input` | `maxLength: 3` | Call `insertText('abcd')` | Text remains empty (input rejected) |
| KC-03 | `minLength validates on Enter only` | `minLength: 3` | Type `ab`; check validation; press Enter; add `c`; Enter again | No error while typing `ab`; Enter fails with `At least 3 characters`; after `abc`, Enter succeeds |

#### Group: `Caps / shift`

| ID | Test name | Preconditions | Steps | Expected result |
|----|-----------|---------------|-------|-----------------|
| KC-04 | `single caps highlights caps mode not shift` | Fresh controller | `onCapsKeyPressed()`; then `toggleShift()` | Caps one-shot on, shift off, uppercase on; after shift toggle, shift on and caps one-shot off |
| KC-05 | `double tap caps enables caps lock` | Fresh controller | Three `onCapsKeyPressed()` calls | 1st: caps one-shot; 2nd: caps lock on, shift/caps one-shot off; 3rd: caps lock off, uppercase off |
| KC-06 | `shift toggles uppercase layout` | Fresh controller | Toggle shift twice | Uppercase false → true → false |

---

### 1.2 `test/numeric_keyboard_controller_test.dart`

Tests [NumericKeyboardController](../lib/core/numericKeyController.dart) with validator: integers 1–200.

| ID | Test name | Preconditions | Steps | Expected result |
|----|-----------|---------------|-------|-----------------|
| NK-01 | `seed value does not show error until user types` | Staging text `0`; set text to `201` without digit keys | — | `validationError` stays `null` (no live error on programmatic text change before edit) |
| NK-02 | `shows range error after user types out of range` | Validator 1–200 | Tap digits `2`, `0`, `1` | Error: `Must be <= 200` |
| NK-03 | `clearValidation resets edit state` | After out-of-range typing | `clearValidation()`; set text to `201` | Error cleared; programmatic `201` still does not show error until user types again |
| NK-04 | `enter always validates even without prior typing` | Text set to `201` without prior digit input | `enter()` | Returns `false`; error `Must be <= 200` |
| NK-05 | `whitespace-only validation is treated as no error` | Validator returns `'   '` | `insertDigit('1')` | `validationError` is `null` (whitespace-only messages ignored) |

---

### 1.3 `test/numeric_range_test.dart`

Tests [NumericRange](../lib/core/numeric_range.dart) min/max parsing and label formatting.

| ID | Test name | Input | Bounds | Expected result |
|----|-----------|-------|--------|-----------------|
| NR-01 | `validates integer bounds` | `25` / `17` / `61` | 18–60 | `null` / `Must be >= 18` / `Must be <= 60` |
| NR-02 | `validates decimal bounds` | `4.2` / `3.0` / `5.6` | 3.1–5.5 | `null` / `Must be >= 3.1` / `Must be <= 5.5` |
| NR-03 | `formatBound trims trailing zeros` | — | — | `3.1`, `5.5`, `18` formatted correctly |

---

### 1.4 `test/onscreen_keyboard_mapping_test.dart`

Tests [preferOnscreenNumericKeyboard](../lib/core/onscreen_keyboard_mapping.dart).

| ID | Test name | Keyboard types | Expected result |
|----|-----------|----------------|-----------------|
| KM-01 | `numeric types use numeric keyboard` | `number`, `phone`, `numberWithOptions(decimal: true)` | All return `true` |
| KM-02 | `text types use custom alpha keyboard` | `text`, `emailAddress`, `multiline`, `name` | All return `false` |

---

### 1.5 `test/onscreen_keyboard_colors_test.dart`

Tests [OnscreenKeyboardColors](../lib/core/onscreen_keyboard_colors.dart) → [KeyboardTheme](../lib/core/theme_controller.dart) mapping.

| ID | Test name | Steps | Expected result |
|----|-----------|-------|-----------------|
| TH-01 | `toTheme maps all required colors` | `colors.toTheme()` | Background, key, text, special, active, pressed, and active text colors match source |
| TH-02 | `KeyboardTheme.fromColors matches toTheme` | Compare `fromColors` vs `toTheme` | Key colors equal for background, key text, active key |

---

## 2. Example app widget tests

Example tests use [test_harness.dart](../example/test/test_harness.dart):

- Viewport: **800×1600** logical pixels (portrait phone).
- `configureKeyboardTests(useCustomKeyboard: true|false)` resets GetX and applies `AppKeyboardTheme`.
- Helpers: `pumpKeyboardDemo`, `tapField`, `typeAlpha`, `typeDigits`, `typeNumber`, `tapEnter`, `dismissOpenKeyboard`.

Demo field keys (see [keyboard_demo_page.dart](../example/lib/keyboard_demo_page.dart)):

| Field key | Keyboard | Notes |
|-----------|----------|-------|
| `field_name` | Custom (QWERTY) | Min length 3, max 24 |
| `field_email` | Custom | Email type |
| `field_username` | Custom | Custom validator |
| `field_memo` | Custom | Multiline |
| `field_age` | Numeric | Range 18–60 |
| `field_quantity` | Numeric | Range 1–200 |
| `field_percent` | Numeric | Range 0–100 |
| `field_pin` | Numeric | Exactly 4 digits |
| `field_even` | Numeric | Even-number validator |
| `field_rating` | Numeric (decimal) | Range 3.1–5.5 |
| `field_amount` | Numeric (decimal) | Range 10–500 |
| `field_weight` | Numeric (decimal) | Range 0.5–500 |
| `field_phone` | Numeric | No min/max |
| `field_zip` | Numeric | No min/max |

---

### 2.1 `example/test/widget_test.dart`

#### Group: `Keyboard demo smoke`

| ID | Test name | Preconditions | Steps | Expected result |
|----|-----------|---------------|-------|-----------------|
| WS-01 | `shows all form sections and field labels` | Custom keyboard enabled | Pump demo | App bar title, Showcase card, section headers (`Custom keyboard`, `Numeric — integers & range`, `Numeric — decimals & range`), rating label, and all 14 `field_*` keys present |

#### Group: `System keyboard mode`

| ID | Test name | Preconditions | Steps | Expected result |
|----|-----------|---------------|-------|-----------------|
| WS-02 | `fields are editable with platform keyboard` | `useCustomKeyboard: false` | Pump demo; tap Name | No custom preview key; Name `readOnly` is false; no `CustomKeyboard` or `NumericKeyboard` in tree |

---

### 2.2 `example/test/all_fields_keyboard_test.dart`

#### Group: `Custom keyboard fields (alpha)`

| ID | Test name | Field | Steps | Expected result |
|----|-----------|-------|-------|-----------------|
| AF-01 | `Name opens QWERTY and commits on Enter` | `field_name` | Tap field; type `ann`; Enter | Custom keyboard + preview visible; after Enter, preview gone; field text `ann` |
| AF-02 | `Name blocks Enter below min length` | `field_name` | Type `ab`; Enter | No error while typing; Enter shows `At least 3 characters`; field stays empty |
| AF-03 | `Email opens QWERTY and commits text` | `field_email` | Tap; type `a`, `t`; Enter | Custom keyboard shown; field text `at` |
| AF-04 | `Memo opens QWERTY and commits text` | `field_memo` | Tap; type `hi`; Enter | Custom keyboard shown; field text `hi` |

#### Group: `Numeric keyboard fields`

| ID | Test name | Field | Steps | Expected result |
|----|-----------|-------|-------|-----------------|
| AF-05 | `Age opens numeric pad with min/max hints` | `field_age` | Tap field | Numeric keyboard only; `Min Value` and `Max Value` labels visible |
| AF-06 | `Age commits in range on Enter` | `field_age` | Type `25`; Enter | Keyboard dismissed; field text `25` |
| AF-07 | `Quantity commits in range on Enter` | `field_quantity` | Type `10`; Enter | Field text `10` |
| AF-08 | `Quantity error clears when switching fields` | `field_quantity` → `field_age` | Type `201` on quantity; tap age | `Must be <= 200` shown; after switching, error gone |
| AF-09 | `Age shows no error until user types` | `field_age` | Tap field only | No `Must be >=` or `Must be <=` messages |
| AF-10 | `Access code validates 4 digits on Enter` | `field_pin` | Type `123`; Enter; type `4`; Enter | First Enter: `Use exactly 4 digits`, field empty; second Enter: field `1234` |
| AF-11 | `Amount commits in range on Enter` | `field_amount` | Type `50`; Enter | Field text `50` |
| AF-12 | `Rating shows decimal bounds on keyboard` | `field_rating` | Tap field | Bounds labels `3.1` and `5.5` visible |
| AF-13 | `Rating commits decimal in range on Enter` | `field_rating` | Type `4.2` (with decimal key); Enter | Field text `4.2` |
| AF-14 | `Rating rejects value above max while typing` | `field_rating` | Type `6` | Live error `Must be <= 5.5` |
| AF-15 | `Rating rejects value below min while typing` | `field_rating` | Type `2` | Live error `Must be >= 3.1` |
| AF-16 | `Phone has no min/max row` | `field_phone` | Tap field | No `Min Value` or `Max Value` in tree |

#### Group: `Switching fields`

| ID | Test name | Steps | Expected result |
|----|-----------|-------|-----------------|
| AF-17 | `switches from alpha to numeric keyboard` | Tap Name (custom); dismiss; tap Age | Custom keyboard for Name; numeric keyboard for Age; custom gone |
| AF-18 | `each field stays readOnly like default custom flow` | Pump demo (no tap) | All 14 demo fields have `readOnly: true` when custom keyboard mode is on |

---

## 3. Coverage map (feature → tests)

| Feature | Unit tests | Widget tests |
|---------|------------|--------------|
| QWERTY typing & shift | KC-01, KC-04–06 | AF-01–04 |
| Min/max text length | KC-02, KC-03 | AF-02 |
| Caps / caps lock | KC-04, KC-05 | — |
| Numeric range (int) | NR-01, NK-02 | AF-05–09, AF-11 |
| Numeric range (decimal) | NR-02, NR-03 | AF-12–15 |
| Live vs Enter validation | NK-01, NK-04, KC-03 | AF-09, AF-14–15 |
| Custom numeric validator | NK-05 | AF-10 |
| Clear error on field switch | NK-03 | AF-08 |
| Keyboard type routing | KM-01, KM-02 | AF-05, AF-01 |
| Theme colors | TH-01, TH-02 | — |
| System keyboard fallback | — | WS-02 |
| Demo UI completeness | — | WS-01 |
| Alpha ↔ numeric switch | — | AF-17 |
| Read-only fields | — | AF-18 |
| No bounds UI | — | AF-16 |

---

## 4. Tests not yet automated

The following demo fields are covered indirectly or only in smoke (WS-01) but have **no dedicated interaction test**:

| Field | Reason / suggestion |
|-------|---------------------|
| `field_username` | Add test: invalid chars → validator error on Enter |
| `field_percent` | Add test: commit `50` in 0–100 range |
| `field_even` | Add test: odd number rejected, even accepted |
| `field_weight` | Add test: decimal commit in 0.5–500 range |
| `field_zip` | Add test: digits commit, no bounds row |
| Landscape draggable keyboard | Requires orientation override in harness |
| Close (X) without clearing text | Manual / future widget test |
| Cursor left/right on custom keyboard | Manual / future widget test |
| Prewarm / keyboard open latency | Performance test, not functional |

---

## 5. Conventions for new tests

1. **Package logic** → add under `test/` with pure unit tests (no `testWidgets` unless UI required).
2. **Demo flows** → add under `example/test/` using `test_harness.dart` helpers.
3. **Field keys** → use `ValueKey<String>('field_*')` matching `keyboard_demo_page.dart`.
4. **Naming** → `group` = feature area; `test` / `testWidgets` = one behavior per test.
5. **IDs** → extend tables in this doc with the next ID in the series (e.g. AF-19).

---

*Last updated from test sources: 38 automated tests across 7 files.*
