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
  static const int _amountMin = 10;
  static const int _amountMax = 500;
  static const int _ageMin = 18;
  static const int _ageMax = 60;
  static const int _quantityMin = 1;
  static const int _quantityMax = 200;
  static const int _nameMinLength = 3;
  static const int _nameMaxLength = 24;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _memoController = TextEditingController();
  final _ageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pinController = TextEditingController();
  final _amountController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _memoFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _pinFocus = FocusNode();
  final _amountFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _memoController.dispose();
    _ageController.dispose();
    _quantityController.dispose();
    _pinController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _memoFocus.dispose();
    _ageFocus.dispose();
    _quantityFocus.dispose();
    _pinFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  String? _pinValidator(String value) {
    if (value.isEmpty) return 'Enter the code';
    if (value.length != 4) return 'Use exactly 4 digits';
    if (int.tryParse(value) == null) return 'Digits only';
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
          Text(
            'Custom keyboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Shift / Caps behave like a default keyboard. Name: min $_nameMinLength, '
            'max $_nameMaxLength. Preview text commits on Enter.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Preview, then Enter',
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
              hintText: 'Free text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Numeric keyboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
            fieldKey: const ValueKey<String>('field_pin'),
            controller: _pinController,
            focusNode: _pinFocus,
            keyboardType: TextInputType.number,
            validator: _pinValidator,
            decoration: const InputDecoration(
              labelText: 'Access code',
              hintText: '4 digits',
              border: OutlineInputBorder(),
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
              labelText: 'Amount',
              hintText: '$_amountMin–$_amountMax',
              border: const OutlineInputBorder(),
            ),
          ),
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
                  ? 'Plugin replaces the system keyboard. Global theme is set in '
                      'main() via FlutterOnscreenKeyboard.configure.'
                  : 'USE_CUSTOM_KEYBOARD=false — fields use the normal system keyboard.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Bullet(
              icon: Icons.keyboard_alt_outlined,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
