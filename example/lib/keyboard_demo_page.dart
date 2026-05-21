import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// Demo: [OnscreenKeyboardHost] + [OnscreenTextField] replace the system keyboard
/// when [OnscreenKeyboardConfig.useCustomKeyboard] is true (see `main.dart`).
class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  static const int _nameMinLength = 3;
  static const int _nameMaxLength = 24;
  static const int _ageMin = 18;
  static const int _ageMax = 60;
  static const int _quantityMin = 1;
  static const int _quantityMax = 200;
  static const num _amountMin = 10;
  static const num _amountMax = 500;
  static const num _ratingMin = 3.1;
  static const num _ratingMax = 5.5;
  static const num _weightMin = 0.5;
  static const num _weightMax = 500;
  static const int _percentMin = 0;
  static const int _percentMax = 100;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _memoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _percentController = TextEditingController();
  final _pinController = TextEditingController();
  final _evenController = TextEditingController();
  final _amountController = TextEditingController();
  final _ratingController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _memoFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _percentFocus = FocusNode();
  final _pinFocus = FocusNode();
  final _evenFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _ratingFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _zipFocus = FocusNode();

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _memoController,
      _usernameController,
      _ageController,
      _quantityController,
      _percentController,
      _pinController,
      _evenController,
      _amountController,
      _ratingController,
      _weightController,
      _phoneController,
      _zipController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _emailFocus,
      _memoFocus,
      _usernameFocus,
      _ageFocus,
      _quantityFocus,
      _percentFocus,
      _pinFocus,
      _evenFocus,
      _amountFocus,
      _ratingFocus,
      _weightFocus,
      _phoneFocus,
      _zipFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  String? _pinValidator(String value) {
    if (value.isEmpty) return 'Enter the code';
    if (value.length != 4) return 'Use exactly 4 digits';
    if (int.tryParse(value) == null) return 'Digits only';
    return null;
  }

  String? _evenValidator(String value) {
    if (value.isEmpty) return 'Enter a number';
    final n = int.tryParse(value);
    if (n == null) return 'Whole numbers only';
    if (n.isOdd) return 'Must be an even number';
    return null;
  }

  String? _emailValidator(String value) =>
      OnscreenKeyboardValidators.email(value);

  String? _usernameValidator(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Letters, numbers, and underscore only';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final usingCustom = FlutterOnscreenKeyboard.useCustomKeyboard;

    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShowcaseIntroCard(
            isLandscape: isLandscape,
            useCustomKeyboard: usingCustom,
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Custom keyboard'),
          const SizedBox(height: 6),
          Text(
            'QWERTY with Shift, Caps (single / double-tap lock), cursor keys, and '
            'Enter-to-commit preview. Name enforces length; email and username '
            'use validators on Enter.',
            style: _sectionSubtitle(context),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_name'),
            controller: _nameController,
            focusNode: _nameFocus,
            keyboardType: TextInputType.text,
            minLength: _nameMinLength,
            maxLength: _nameMaxLength,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: '$_nameMinLength–$_nameMaxLength characters',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_email'),
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Valid email required on Enter',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_username'),
            controller: _usernameController,
            focusNode: _usernameFocus,
            keyboardType: TextInputType.text,
            validator: _usernameValidator,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Custom validator on Enter',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_memo'),
            controller: _memoController,
            focusNode: _memoFocus,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Memo',
              hintText: 'Multiline free text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Numeric — integers & range'),
          const SizedBox(height: 6),
          Text(
            'Whole numbers with min/max on the keyboard. Errors appear while typing '
            'after the first key; switching fields clears validation.',
            style: _sectionSubtitle(context),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_age'),
            controller: _ageController,
            focusNode: _ageFocus,
            keyboardType: TextInputType.number,
            minValue: _ageMin,
            maxValue: _ageMax,
            decoration: InputDecoration(
              labelText: 'Age ($_ageMin – $_ageMax)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_quantity'),
            controller: _quantityController,
            focusNode: _quantityFocus,
            keyboardType: TextInputType.number,
            minValue: _quantityMin,
            maxValue: _quantityMax,
            decoration: InputDecoration(
              labelText: 'Quantity ($_quantityMin – $_quantityMax)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_percent'),
            controller: _percentController,
            focusNode: _percentFocus,
            keyboardType: TextInputType.number,
            minValue: _percentMin,
            maxValue: _percentMax,
            decoration: InputDecoration(
              labelText: 'Percent ($_percentMin – $_percentMax)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Numeric — decimals & range'),
          const SizedBox(height: 6),
          Text(
            'Decimal pad (0–9 and .). Range supports fractional bounds, e.g. rating '
            '$_ratingMin–$_ratingMax.',
            style: _sectionSubtitle(context),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_rating'),
            controller: _ratingController,
            focusNode: _ratingFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            minValue: _ratingMin,
            maxValue: _ratingMax,
            decoration: InputDecoration(
              labelText: 'Rating ($_ratingMin – $_ratingMax)',
              hintText: 'Try 4.2',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_amount'),
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            minValue: _amountMin,
            maxValue: _amountMax,
            decoration: InputDecoration(
              labelText: 'Amount ($_amountMin – $_amountMax)',
              hintText: 'Decimal allowed',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_weight'),
            controller: _weightController,
            focusNode: _weightFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            minValue: _weightMin,
            maxValue: _weightMax,
            decoration: InputDecoration(
              labelText: 'Weight ($_weightMin – $_weightMax kg)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Numeric — custom validator'),
          const SizedBox(height: 6),
          Text(
            'Range is optional. Custom [validator] runs on Enter (and live for numeric '
            'after typing when combined with range).',
            style: _sectionSubtitle(context),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_pin'),
            controller: _pinController,
            focusNode: _pinFocus,
            keyboardType: TextInputType.number,
            maxLength: 4,
            validator: _pinValidator,
            decoration: const InputDecoration(
              labelText: 'Access code',
              hintText: 'Exactly 4 digits',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_even'),
            controller: _evenController,
            focusNode: _evenFocus,
            keyboardType: TextInputType.number,
            validator: _evenValidator,
            decoration: const InputDecoration(
              labelText: 'Even number',
              hintText: 'Validator only (no min/max row)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Numeric — no range'),
          const SizedBox(height: 6),
          Text(
            'Phone and ZIP use the numeric pad without min/max labels.',
            style: _sectionSubtitle(context),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_phone'),
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'No min/max',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_zip'),
            controller: _zipController,
            focusNode: _zipFocus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ZIP code',
              hintText: 'Digits only, no bounds',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('On-screen Keyboard Demo')),
      body: SafeArea(
        child: OnscreenKeyboardHost(
          commitOnEnterOnly: true,
          child: form,
        ),
      ),
    );
  }

  TextStyle? _sectionSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ShowcaseIntroCard extends StatelessWidget {
  const _ShowcaseIntroCard({
    required this.isLandscape,
    required this.useCustomKeyboard,
  });

  final bool isLandscape;
  final bool useCustomKeyboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Showcase',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              useCustomKeyboard
                  ? 'Plugin replaces the system keyboard. Theme from '
                      'FlutterOnscreenKeyboard.configure in main().'
                  : 'USE_CUSTOM_KEYBOARD=false — fields use the system keyboard.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const _Bullet(
              icon: Icons.keyboard_alt_outlined,
              text: 'Custom: name length, email, username validator, memo.',
            ),
            const _Bullet(
              icon: Icons.pin_outlined,
              text: 'Numeric int range: age, quantity, percent.',
            ),
            const _Bullet(
              icon: Icons.star_half,
              text: 'Numeric decimal range: rating 3.1–5.5, amount, weight.',
            ),
            const _Bullet(
              icon: Icons.rule_folder_outlined,
              text: 'Validator-only: 4-digit PIN, even number; no range: phone, ZIP.',
            ),
            const SizedBox(height: 8),
            _Bullet(
              icon: Icons.screen_rotation_outlined,
              text: isLandscape
                  ? 'Landscape: draggable keyboard panel.'
                  : 'Portrait: keyboard fixed to the bottom.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
