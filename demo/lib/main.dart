import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

import 'app_keyboard_theme.dart';

void main() {
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: DemoAppTheme.aurora.darkKeyboard,
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
  int _presetIndex = 0;
  bool _syncingKeyboardPalette = false;

  DemoThemePreset get _preset => DemoAppTheme.presetAt(_presetIndex);

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onThemeControllerChanged);
    _applyPreset(applyBrightness: false);
  }

  @override
  void dispose() {
    _tc.removeListener(_onThemeControllerChanged);
    super.dispose();
  }

  void _onThemeControllerChanged() {
    if (_syncingKeyboardPalette) return;
    _applyPreset(applyBrightness: false);
  }

  void _setPresetIndex(int index) {
    if (index == _presetIndex) return;
    setState(() => _presetIndex = index);
    _applyPreset();
  }

  void _toggleBrightness() {
    _tc.setDarkMode(!_tc.isDarkMode);
    _applyPreset();
  }

  void _applyPreset({bool applyBrightness = true}) {
    final preset = _preset;
    final keyboard = preset.keyboardFor(
      _tc.isDarkMode ? Brightness.dark : Brightness.light,
    );

    if (_tc.keyboardTheme.backgroundColor == keyboard.background &&
        _tc.keyboardTheme.keyBackgroundColor == keyboard.keyBackground &&
        _tc.keyboardTheme.keyTextColor == keyboard.keyText) {
      return;
    }

    _syncingKeyboardPalette = true;
    try {
      _tc.applyKeyboardColors(
        keyboard,
        isDarkMode: applyBrightness ? _tc.isDarkMode : null,
      );
    } finally {
      _syncingKeyboardPalette = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    return ListenableBuilder(
      listenable: _tc,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Personal Details Form',
          themeMode: _tc.themeMode,
          theme: DemoAppTheme.materialTheme(Brightness.light, preset),
          darkTheme: DemoAppTheme.materialTheme(Brightness.dark, preset),
          builder: (context, child) {
            return OnscreenKeyboardAttachment(
              commitOnEnterOnly: true,
              useDraggableInLandscape: true,
              lockContentWhileKeyboardVisible: true,
              dismissOnTapOutside: false,
              dismissOnSystemBack: false,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: PersonalDetailsPage(
            isDark: _tc.isDarkMode,
            presetIndex: _presetIndex,
            onPresetSelected: _setPresetIndex,
            onToggleBrightness: _toggleBrightness,
          ),
        );
      },
    );
  }
}

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({
    super.key,
    required this.isDark,
    required this.presetIndex,
    required this.onPresetSelected,
    required this.onToggleBrightness,
  });

  final bool isDark;
  final int presetIndex;
  final ValueChanged<int> onPresetSelected;
  final VoidCallback onToggleBrightness;

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();

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
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter email';
    return OnscreenKeyboardValidators.email(v);
  }

  String? _phoneValidator(String? value) {
    final v = value ?? '';
    if (v.length != _phoneLength) {
      return 'Use exactly $_phoneLength digits';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form Submitted')),
    );
  }

  String? _nameFormValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < _nameMinLength) {
      return 'At least $_nameMinLength characters';
    }
    return null;
  }

  Widget _themePresetPicker(BuildContext context) {
    final preset = DemoAppTheme.presetAt(widget.presetIndex);
    final keyboard = preset.keyboardFor(
      widget.isDark ? Brightness.dark : Brightness.light,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keyboard theme',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${preset.name} · ${widget.isDark ? 'Dark' : 'Light'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(DemoAppTheme.presets.length, (index) {
            final p = DemoAppTheme.presets[index];
            final kb = p.keyboardFor(
              widget.isDark ? Brightness.dark : Brightness.light,
            );
            final selected = index == widget.presetIndex;
            return FilterChip(
              label: Text(p.name),
              selected: selected,
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: kb.background,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: kb.activeKey,
                ),
              ),
              onSelected: (_) => widget.onPresetSelected(index),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: keyboard.previewBackground,
            border: Border.all(
              color: keyboard.previewBorder ??
                  keyboard.keyBorder ??
                  preset.seedColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Preview text Aa123',
            style: TextStyle(
              color: keyboard.previewText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final form = Form(
      key: _formKey,
      child: SingleChildScrollView(
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
                    'Uses OnscreenTextFormField (TextFormField + all keyboard '
                    'rules). Wire your app with OnscreenKeyboardBinding and '
                    'OnscreenKeyboardAttachment in MaterialApp.builder.',
                  ),
                  const SizedBox(height: 12),
                  _themePresetPicker(context),
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
          OnscreenTextFormField(
            controller: _nameController,
            keyboardType: TextInputType.text,
            minLength: _nameMinLength,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: '$_nameMinLength–$_nameMaxLength characters',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: _nameFormValidator,
          ),
          const SizedBox(height: 15),
          OnscreenTextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: _emailValidator,
          ),
          const SizedBox(height: 15),
          OnscreenTextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: _phoneLength,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: _phoneValidator,
          ),
          const SizedBox(height: 15),
          OnscreenTextFormField(
            controller: _weightController,
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
          OnscreenTextFormField(
            controller: _ageController,
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
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Switch to light' : 'Switch to dark',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleBrightness,
          ),
        ],
      ),
      body: SafeArea(child: form),
    );
  }
}
