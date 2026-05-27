import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

import 'app_keyboard_theme.dart';

void main() {
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: DemoAppTheme.keyboardDark,
      useCustomKeyboard: true,
      replaceDefaultTheme: true,
    ),
  );

  runApp(const OnscreenKeyboardBinding(child: DemoRoot()));
}

/// Root widget — listens to [FlutterOnscreenKeyboard.themeController] and
/// rebuilds the [MaterialApp] whenever the keyboard theme / brightness flips.
class DemoRoot extends StatefulWidget {
  const DemoRoot({super.key});

  @override
  State<DemoRoot> createState() => _DemoRootState();
}

class _DemoRootState extends State<DemoRoot> {
  final ThemeController _tc = FlutterOnscreenKeyboard.themeController;
  bool _syncingKeyboardPalette = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_syncKeyboardThemeWithMode);
    _syncKeyboardThemeWithMode();
  }

  @override
  void dispose() {
    _tc.removeListener(_syncKeyboardThemeWithMode);
    super.dispose();
  }

  void _syncKeyboardThemeWithMode() {
    if (_syncingKeyboardPalette) return;
    final target = _tc.isDarkMode
        ? DemoAppTheme.keyboardDark
        : DemoAppTheme.keyboardLight;

    // Skip if already using this palette to avoid notification loops.
    if (_tc.keyboardTheme.backgroundColor == target.background &&
        _tc.keyboardTheme.keyBackgroundColor == target.keyBackground &&
        _tc.keyboardTheme.keyTextColor == target.keyText) {
      return;
    }

    _syncingKeyboardPalette = true;
    try {
      _tc.applyKeyboardColors(target, isDarkMode: _tc.isDarkMode);
    } finally {
      _syncingKeyboardPalette = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tc,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Personal Details Form',
          themeMode: _tc.themeMode,
          theme: DemoAppTheme.materialTheme(Brightness.light),
          darkTheme: DemoAppTheme.materialTheme(Brightness.dark),
          home: PersonalDetailsPage(isDark: _tc.isDarkMode),
        );
      },
    );
  }
}

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key, required this.isDark});

  final bool isDark;

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  static const int _nameMinLength = 3;
  static const int _nameMaxLength = 24;
  static const int _ageMin = 1;
  static const int _ageMax = 120;
  static const num _weightMin = 0.5;
  static const num _weightMax = 500;
  static const int _phoneLength = 10;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _ageFocus = FocusNode();

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _weightController,
      _ageController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _emailFocus,
      _phoneFocus,
      _weightFocus,
      _ageFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  String? _emailValidator(String value) {
    if (value.trim().isEmpty) return 'Please enter email';
    return OnscreenKeyboardValidators.email(value);
  }

  String? _phoneValidator(String value) {
    if (value.length != _phoneLength) {
      return 'Use exactly $_phoneLength digits';
    }
    return null;
  }

  void _toggleTheme() {
    final tc = FlutterOnscreenKeyboard.themeController;
    final goingDark = !tc.isDarkMode;
    tc.applyKeyboardColors(
      goingDark ? DemoAppTheme.keyboardDark : DemoAppTheme.keyboardLight,
      isDarkMode: goingDark,
    );
  }

  void _submit() {
    final missing = <String>[
      if (_nameController.text.trim().isEmpty) 'Name',
      if (_emailController.text.trim().isEmpty) 'Email',
      if (_phoneController.text.trim().isEmpty) 'Phone',
      if (_weightController.text.trim().isEmpty) 'Weight',
      if (_ageController.text.trim().isEmpty) 'Age',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill: ${missing.join(', ')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form Submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom keyboard demo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Same integration as the example app: OnscreenKeyboardHost '
                    '+ OnscreenTextField. Type in the keyboard preview; press '
                    'Enter to commit. Close with X only.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLandscape
                        ? 'Landscape: draggable keyboard panel.'
                        : 'Portrait: keyboard docked at the bottom.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_name'),
            controller: _nameController,
            focusNode: _nameFocus,
            keyboardType: TextInputType.text,
            minLength: _nameMinLength,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: '$_nameMinLength–$_nameMaxLength characters',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_email'),
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_phone'),
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            maxLength: _phoneLength,
            validator: _phoneValidator,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_weight'),
            controller: _weightController,
            focusNode: _weightFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            minValue: _weightMin,
            maxValue: _weightMax,
            maxFractionDigits: 2,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: '$_weightMin–$_weightMax',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          OnscreenTextField(
            fieldKey: const ValueKey<String>('field_age'),
            controller: _ageController,
            focusNode: _ageFocus,
            keyboardType: TextInputType.number,
            minValue: _ageMin,
            maxValue: _ageMax,
            integersOnly: true,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: '$_ageMin–$_ageMax',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Switch to light' : 'Switch to dark',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: OnscreenKeyboardHost(
          commitOnEnterOnly: true,
          useDraggableInLandscape: true,
          dismissOnTapOutside: false,
          child: form,
        ),
      ),
    );
  }
}
