import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

/// Demo page for [CustomKeyboard] (QWERTY, preview until Enter, optional
/// validators) and [NumericKeyboard] (digits, optional min/max on the panel,
/// Enter to commit).
class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  static const int _amountMin = 10;
  static const int _amountMax = 500;

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

  TextEditingController? _activeController;
  FocusNode? _activeFocusNode;
  bool _useNumericKeyboard = false;

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

  void _activateAlpha(TextEditingController controller, FocusNode focusNode) {
    setState(() {
      _activeController = controller;
      _activeFocusNode = focusNode;
      _useNumericKeyboard = false;
    });
    focusNode.requestFocus();
  }

  void _activateNumeric(TextEditingController controller, FocusNode focusNode) {
    setState(() {
      _activeController = controller;
      _activeFocusNode = focusNode;
      _useNumericKeyboard = true;
    });
    focusNode.requestFocus();
  }

  String? _ageValidator(String value) {
    if (value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null) return 'Age must be a whole number';
    if (age < 18 || age > 60) return 'Age must be between 18 and 60';
    return null;
  }

  String? _quantityValidator(String value) {
    if (value.isEmpty) return 'Quantity is required';
    final quantity = int.tryParse(value);
    if (quantity == null) return 'Quantity must be a number';
    if (quantity < 1 || quantity > 200) {
      return 'Quantity must be between 1 and 200';
    }
    return null;
  }

  String? _pinValidator(String value) {
    if (value.isEmpty) return 'Enter the code';
    if (value.length != 4) return 'Use exactly 4 digits';
    if (int.tryParse(value) == null) return 'Digits only';
    return null;
  }

  String? Function(String)? alphaValidator() {
    if (_activeFocusNode == _ageFocus) return _ageValidator;
    if (_activeFocusNode == _quantityFocus) return _quantityValidator;
    return null;
  }

  String? Function(String)? numericValidator() {
    if (_activeFocusNode == _pinFocus) return _pinValidator;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    int? numericKeyboardMin;
    int? numericKeyboardMax;
    if (_useNumericKeyboard &&
        _activeFocusNode != null &&
        _activeFocusNode == _amountFocus) {
      numericKeyboardMin = _amountMin;
      numericKeyboardMax = _amountMax;
    }

    final formContent = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ShowcaseIntroCard(isLandscape: isLandscape),
        const SizedBox(height: 20),
        Text(
          'Custom keyboard',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Letters, numbers row, Caps, and symbols. Typed text stays in a '
          'preview until you press Enter (then it commits to the field). '
          'Age and Quantity add custom validation on commit.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Name',
          hint: 'Plain text, no extra rules',
          controller: _nameController,
          focusNode: _nameFocus,
          onTap: () => _activateAlpha(_nameController, _nameFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Email',
          hint: 'Same keyboard — preview, then Enter',
          controller: _emailController,
          focusNode: _emailFocus,
          onTap: () => _activateAlpha(_emailController, _emailFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Memo',
          hint: 'Longer free text on the alpha keyboard',
          controller: _memoController,
          focusNode: _memoFocus,
          onTap: () => _activateAlpha(_memoController, _memoFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Age (18 – 60)',
          hint: 'Validator: whole number in range',
          controller: _ageController,
          focusNode: _ageFocus,
          onTap: () => _activateAlpha(_ageController, _ageFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Quantity (1 – 200)',
          hint: 'Another validated alpha commit',
          controller: _quantityController,
          focusNode: _quantityFocus,
          onTap: () => _activateAlpha(_quantityController, _quantityFocus),
        ),
        const SizedBox(height: 28),
        Text(
          'Numeric keyboard',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Digits only. You can use it with no range (Access code), or with '
          'Min / Max shown on the keyboard (Amount). Enter commits when valid.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Access code',
          hint: '4 digits — no min/max on keyboard, custom rule on Enter',
          controller: _pinController,
          focusNode: _pinFocus,
          onTap: () => _activateNumeric(_pinController, _pinFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Amount',
          hint:
              'Min / max $_amountMin–$_amountMax on keyboard; Enter must pass range',
          controller: _amountController,
          focusNode: _amountFocus,
          onTap: () => _activateNumeric(_amountController, _amountFocus),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('On-screen Keyboard Demo')),
      body: SafeArea(
        child: _activeController != null && _activeFocusNode != null
            ? (isLandscape
                  ? DraggableDynamicKeyboard(
                      controller: _activeController!,
                      focusNode: _activeFocusNode!,
                      validator: _useNumericKeyboard
                          ? numericValidator()
                          : alphaValidator(),
                      numericMinValue: numericKeyboardMin,
                      numericMaxValue: numericKeyboardMax,
                      widthFactor: 0.5,
                      heightFactor: 0.5,
                      fullWidthInLandscape: false,
                      alwaysVisible: true,
                      pushContent: false,
                      useNumericKeyboard: _useNumericKeyboard,
                      child: formContent,
                      onEnterPressed: () {
                        setState(() {
                          _activeController = null;
                          _activeFocusNode = null;
                          _useNumericKeyboard = false;
                        });
                      },
                    )
                  : Column(
                      children: [
                        Expanded(child: formContent),
                        if (_useNumericKeyboard)
                          NumericKeyboard(
                            controller: _activeController!,
                            focusNode: _activeFocusNode!,
                            commitOnEnterOnly: true,
                            minValue: numericKeyboardMin,
                            maxValue: numericKeyboardMax,
                            validator: numericValidator(),
                            onEnterPressed: () {
                              setState(() {
                                _activeController = null;
                                _activeFocusNode = null;
                                _useNumericKeyboard = false;
                              });
                            },
                          )
                        else
                          CustomKeyboard(
                            controller: _activeController!,
                            focusNode: _activeFocusNode!,
                            commitOnEnterOnly: true,
                            validator: alphaValidator(),
                            onEnterPressed: () {
                              setState(() {
                                _activeController = null;
                                _activeFocusNode = null;
                                _useNumericKeyboard = false;
                              });
                            },
                          ),
                      ],
                    ))
            : formContent,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true,
      showCursor: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ShowcaseIntroCard extends StatelessWidget {
  const _ShowcaseIntroCard({required this.isLandscape});

  final bool isLandscape;

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen compares the two base widgets from the package: '
              'CustomKeyboard for general typing and NumericKeyboard for '
              'integer-style input. Tap a field to open the matching keyboard.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Bullet(
              icon: Icons.keyboard_alt_outlined,
              text: isLandscape
                  ? 'Landscape: floating draggable panel (same widgets, '
                        'different chrome).'
                  : 'Portrait: keyboard is fixed to the bottom of the screen.',
            ),
            const SizedBox(height: 6),
            const _Bullet(
              icon: Icons.touch_app_outlined,
              text:
                  'Dismiss by pressing Enter after a valid commit, or tap '
                  'outside the keys.',
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
