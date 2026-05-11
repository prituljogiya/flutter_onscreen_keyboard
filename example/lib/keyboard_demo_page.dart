import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/custom_keyboard.dart';

class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  static const int _singleFieldMin = 10;
  static const int _singleFieldMax = 500;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _quantityController = TextEditingController();

  final _amountController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _amountFocus = FocusNode();

  TextEditingController? _activeController;
  FocusNode? _activeFocusNode;
  bool _useNumericKeyboard = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _ageFocus.dispose();
    _quantityFocus.dispose();
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;

    final formContent = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Text fields (letters)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildReadOnlyField(
          label: 'Name',
          hint: 'Tap — type in keyboard preview, Enter commits',
          controller: _nameController,
          focusNode: _nameFocus,
          onTap: () => _activateAlpha(_nameController, _nameFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Email',
          hint: 'Tap — type in keyboard preview, Enter commits',
          controller: _emailController,
          focusNode: _emailFocus,
          onTap: () => _activateAlpha(_emailController, _emailFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Age (18 - 60)',
          hint: 'Tap — numeric rules on commit',
          controller: _ageController,
          focusNode: _ageFocus,
          onTap: () => _activateAlpha(_ageController, _ageFocus),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Quantity (1 - 200)',
          hint: 'Tap — numeric rules on commit',
          controller: _quantityController,
          focusNode: _quantityFocus,
          onTap: () => _activateAlpha(_quantityController, _quantityFocus),
        ),
        const SizedBox(height: 24),
        const Text(
          'Single numeric field (min / max on keyboard)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Only one field. Its allowed range is set in code (here $_singleFieldMin–'
          '$_singleFieldMax). The keyboard shows Min / Max and only commits on '
          'Enter if the value is inside that range.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.purple.shade900.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField(
          label: 'Amount',
          hint:
              'Tap — numeric keyboard, range $_singleFieldMin–$_singleFieldMax',
          controller: _amountController,
          focusNode: _amountFocus,
          onTap: () => _activateNumeric(_amountController, _amountFocus),
        ),
      ],
    );

    String? Function(String)? alphaValidator() {
      if (_activeFocusNode == _ageFocus) return _ageValidator;
      if (_activeFocusNode == _quantityFocus) return _quantityValidator;
      return null;
    }

    int? numericKeyboardMin;
    int? numericKeyboardMax;
    if (_useNumericKeyboard &&
        _activeFocusNode != null &&
        _activeController != null &&
        _activeFocusNode == _amountFocus) {
      numericKeyboardMin = _singleFieldMin;
      numericKeyboardMax = _singleFieldMax;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('On-screen Keyboard Demo')),
      body: SafeArea(
        child: _activeController != null && _activeFocusNode != null
            ? (isLandscape
                  ? DraggableDynamicKeyboard(
                      controller: _activeController!,
                      focusNode: _activeFocusNode!,
                      validator: _useNumericKeyboard ? null : alphaValidator(),
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
