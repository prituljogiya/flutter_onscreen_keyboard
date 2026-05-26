import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// One palette drives both [ThemeData] and the keyboard's
/// [OnscreenKeyboardColors] so the on-screen keyboard matches the brand.
class AppPalette {
  AppPalette._();

  // Brand colors.
  static const Color primary = Color(0xFF4A3F8C); // deep indigo
  static const Color accent = Color(0xFF00CFC1); // teal

  /// Dark keyboard palette (default when the app is in dark mode).
  static const OnscreenKeyboardColors keyboardDark = OnscreenKeyboardColors(
    background: Color(0xFF1E1E2C),
    keyBackground: Color(0xFF2A2A3D),
    keyText: Color(0xFFFFFFFF),
    specialKeyBackground: Color(0xFF3D3D56),
    specialKeyText: accent,
    activeKey: primary,
    activeKeyText: Color(0xFFFFFFFF),
    keyPressed: Color(0xFF5C57B6),
    borderRadius: 10,
    keySpacing: 6,
    fontSize: 17,
  );

  /// Light keyboard palette (used when the app toggles to light mode).
  static const OnscreenKeyboardColors keyboardLight = OnscreenKeyboardColors(
    background: Color(0xFFEEEAFB),
    keyBackground: Color(0xFFFFFFFF),
    keyText: Color(0xFF1B1B2E),
    specialKeyBackground: Color(0xFFD4CCFC),
    specialKeyText: primary,
    activeKey: primary,
    activeKeyText: Color(0xFFFFFFFF),
    keyPressed: Color(0xFFB8AEF7),
    borderRadius: 10,
    keySpacing: 6,
    fontSize: 17,
  );
}

void main() {
  // Same one-shot setup the example uses. The OnscreenKeyboardColors here are
  // the *starting* palette — we'll swap them when the user taps the
  // theme-toggle button below.
  FlutterOnscreenKeyboard.configure(
    OnscreenKeyboardConfig.withColors(
      colors: AppPalette.keyboardDark,
      useCustomKeyboard: true,
      replaceDefaultTheme: true,
      // Lock the keyboard theme in debug so a hot reload doesn't reset our
      // chosen palette. Production builds still respect explicit toggles.
      lockKeyboardTheme: kDebugMode,
    ),
  );

  runApp(const OnscreenKeyboardBinding(child: DemoRoot()));
}

/// Root widget — listens to [FlutterOnscreenKeyboard.themeController] and
/// rebuilds the [MaterialApp] whenever the keyboard theme / brightness flips.
/// Same pattern as `example/lib/main.dart`.
class DemoRoot extends StatelessWidget {
  const DemoRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = FlutterOnscreenKeyboard.themeController;
    return ListenableBuilder(
      listenable: tc,
      builder: (context, _) {
        final isDark = tc.isDarkMode;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Personal Details Form',
          themeMode: tc.themeMode,
          theme: _appTheme(Brightness.light),
          darkTheme: _appTheme(Brightness.dark),
          home: PersonalDetailsPage(isDark: isDark),
        );
      },
    );
  }

  ThemeData _appTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
      primary: AppPalette.primary,
      secondary: AppPalette.accent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF15151E)
          : const Color(0xFFF6F4FB),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppPalette.primary, width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : AppPalette.primary,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
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
  // Field constraints (same pattern the example uses — declare bounds in
  // one place and reuse for hint text + validators).
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

  /// Flip both the Material brightness AND the keyboard palette in one go.
  void _toggleTheme() {
    final tc = FlutterOnscreenKeyboard.themeController;
    final goingDark = !tc.isDarkMode;
    tc.toggleTheme();
    tc.updateTheme(
      KeyboardTheme.fromColors(
        goingDark ? AppPalette.keyboardDark : AppPalette.keyboardLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name → alpha keyboard. Length-bounded; the keyboard panel
          // surfaces "At least 3 characters" on Enter when too short.
          OnscreenTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            keyboardType: TextInputType.text,
            minLength: _nameMinLength,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: '$_nameMinLength–$_nameMaxLength characters',
            ),
          ),
          const SizedBox(height: 15),

          // Email → alpha keyboard with email validator on Enter.
          OnscreenTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 15),

          // Phone → numeric keyboard, fixed length, custom validator.
          OnscreenTextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            maxLength: _phoneLength,
            validator: _phoneValidator,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          const SizedBox(height: 15),

          // Weight → numeric keyboard with decimal, range-bounded.
          OnscreenTextField(
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
            ),
          ),
          const SizedBox(height: 15),

          // Age → numeric keyboard, integers only, range-bounded.
          OnscreenTextField(
            controller: _ageController,
            focusNode: _ageFocus,
            keyboardType: TextInputType.number,
            minValue: _ageMin,
            maxValue: _ageMax,
            integersOnly: true,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: '$_ageMin–$_ageMax',
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
      // Same pattern as `example/lib/keyboard_demo_page.dart`:
      //   - portrait → keyboard docks at the bottom and pushes the form up
      //   - landscape → keyboard renders as a draggable card (alpha or numeric)
      //   - numeric vs alpha is picked automatically per OnscreenTextField.keyboardType
      //   - Enter validates the value through OnscreenTextField.validator /
      //     minLength / maxLength / minValue / maxValue before committing.
      body: SafeArea(
        child: OnscreenKeyboardHost(
          commitOnEnterOnly: true,
          useDraggableInLandscape: true,
          child: form,
        ),
      ),
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
    final messenger = ScaffoldMessenger.of(context);
    if (missing.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Please fill: ${missing.join(', ')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Form Submitted')),
    );
  }
}
