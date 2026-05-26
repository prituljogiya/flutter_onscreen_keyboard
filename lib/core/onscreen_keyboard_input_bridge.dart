import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'onscreen_keyboard_mapping.dart' as keyboard_mapping;

/// Singleton that bridges Flutter's [TextInput] pipeline to the on-screen
/// keyboard panel.
///
/// Once [OnscreenKeyboardInputControl] is installed (see
/// [OnscreenKeyboardAttachment]) the bridge gets attach / detach / show / hide
/// / setEditingState callbacks from the framework. The keyboard widgets
/// (`CustomKeyboard`, `NumericKeyboard`) drive the bridge's [controller], and
/// the bridge pushes every controller change back to the framework via
/// [TextInput.updateEditingValue].
///
/// The whole point of this class is to let **any** vanilla [TextField] /
/// [TextFormField] use the on-screen keyboard without being wrapped in
/// [OnscreenTextField] or [OnscreenKeyboardHost].
class OnscreenKeyboardInputBridge extends ChangeNotifier {
  OnscreenKeyboardInputBridge._() {
    controller.addListener(_onLocalChange);
  }

  /// Process-wide singleton.
  static final OnscreenKeyboardInputBridge instance =
      OnscreenKeyboardInputBridge._();

  /// Synthetic editing controller mirroring the active client's value.
  final TextEditingController controller = TextEditingController();

  /// Placeholder focus node passed to the keyboard widgets. The "real" focus
  /// is on the framework's [EditableText]; we only need this so the existing
  /// `KeyboardController` API has something to call `unfocus()` on.
  final FocusNode focusNode = FocusNode(debugLabel: 'onscreenAutoFocus');

  TextInputClient? _client;
  TextInputConfiguration? _config;
  bool _visible = false;

  /// Guard so that a controller change driven by [setEditingState] (i.e. the
  /// framework telling us "the value is now X") does not echo straight back
  /// out via [TextInput.updateEditingValue].
  bool _internalUpdate = false;

  bool get isAttached => _client != null;
  bool get isVisible => _visible && isAttached;
  TextInputConfiguration? get configuration => _config;

  /// Whether the active client wants a numeric keyboard.
  bool get useNumericKeyboard {
    final cfg = _config;
    if (cfg == null) return false;
    return keyboard_mapping.preferOnscreenNumericKeyboard(cfg.inputType);
  }

  /// Decimal key visibility for the numeric pad — inferred from the input
  /// type (decimal-enabled variants show it).
  bool get showDecimalKey {
    final cfg = _config;
    if (cfg == null) return true;
    return cfg.inputType.decimal == true || !integersOnly;
  }

  /// Whether integers-only validation applies (TextInputType.number without
  /// `decimal: true`).
  bool get integersOnly {
    final cfg = _config;
    if (cfg == null) return false;
    return keyboard_mapping.integersOnlyKeyboardType(cfg.inputType);
  }

  /// The action the framework wants for the Enter key.
  TextInputAction get inputAction =>
      _config?.inputAction ?? TextInputAction.done;

  // ---------------------------------------------------------------------------
  // Hooks invoked by [OnscreenKeyboardInputControl] — i.e. the framework.
  // ---------------------------------------------------------------------------

  void handleAttach(TextInputClient client, TextInputConfiguration cfg) {
    _client = client;
    _config = cfg;
    _visible = true;
    notifyListeners();
  }

  void handleDetach(TextInputClient client) {
    if (!identical(_client, client)) return;
    _client = null;
    _config = null;
    _visible = false;
    _resetController();
    notifyListeners();
  }

  void handleShow() {
    if (_visible || !isAttached) return;
    _visible = true;
    notifyListeners();
  }

  void handleHide() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }

  void handleUpdateConfig(TextInputConfiguration cfg) {
    _config = cfg;
    notifyListeners();
  }

  /// Framework → bridge: the field's editing value changed externally
  /// (programmatic edit, controller.text = ..., autofill, etc.).
  void handleSetEditingState(TextEditingValue value) {
    if (controller.value == value) return;
    _internalUpdate = true;
    try {
      controller.value = value;
    } finally {
      _internalUpdate = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Hooks invoked by the keyboard widgets — i.e. user taps.
  // ---------------------------------------------------------------------------

  /// Called by the Enter key. Forwards the action to the active client. For
  /// terminal actions (done / go / send / search) we also dismiss the panel
  /// and drop framework focus so the user lands back on the form.
  void performAction() {
    final client = _client;
    final action = inputAction;
    if (client != null) {
      client.performAction(action);
    }
    if (_isTerminalAction(action)) {
      _dropFocus();
    }
  }

  /// Called when the user taps the keyboard panel's close (X) or otherwise
  /// requests dismissal. Hides the panel and unfocuses the active field so
  /// the framework tears down the input connection cleanly.
  void dismiss() {
    _dropFocus();
  }

  void _dropFocus() {
    handleHide();
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus();
    }
  }

  void _onLocalChange() {
    if (_internalUpdate || _client == null) return;
    TextInput.updateEditingValue(controller.value);
  }

  void _resetController() {
    _internalUpdate = true;
    try {
      controller.value = TextEditingValue.empty;
    } finally {
      _internalUpdate = false;
    }
  }

  bool _isTerminalAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.send:
      case TextInputAction.search:
      case TextInputAction.join:
      case TextInputAction.route:
      case TextInputAction.emergencyCall:
      case TextInputAction.continueAction:
      case TextInputAction.previous:
      case TextInputAction.unspecified:
        return true;
      case TextInputAction.next:
      case TextInputAction.newline:
      case TextInputAction.none:
        return false;
    }
  }
}

/// Hooks the on-screen keyboard into Flutter's text input pipeline.
///
/// Installed by [OnscreenKeyboardAttachment]; the framework routes every
/// editing-related call (attach, detach, show, hide, setEditingState, …) to
/// this control instead of the platform IME, which is what suppresses the
/// system keyboard automatically.
class OnscreenKeyboardInputControl with TextInputControl {
  OnscreenKeyboardInputControl._();

  /// Process-wide singleton, paired 1:1 with [OnscreenKeyboardInputBridge].
  static final OnscreenKeyboardInputControl instance =
      OnscreenKeyboardInputControl._();

  OnscreenKeyboardInputBridge get _bridge =>
      OnscreenKeyboardInputBridge.instance;

  /// Reference-counted install/uninstall so multiple [OnscreenKeyboardAttachment]
  /// instances (e.g. tests, nested apps) do not stomp on each other.
  int _installCount = 0;

  /// Replace the platform input control. Idempotent — subsequent calls just
  /// bump the reference count.
  void install() {
    _installCount++;
    if (_installCount == 1) {
      TextInput.setInputControl(this);
    }
  }

  /// Restore the platform input control when the last consumer goes away.
  void uninstall() {
    if (_installCount == 0) return;
    _installCount--;
    if (_installCount == 0) {
      TextInput.restorePlatformInputControl();
    }
  }

  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    _bridge.handleAttach(client, configuration);
  }

  @override
  void detach(TextInputClient client) {
    _bridge.handleDetach(client);
  }

  @override
  void show() => _bridge.handleShow();

  @override
  void hide() => _bridge.handleHide();

  @override
  void setEditingState(TextEditingValue value) {
    _bridge.handleSetEditingState(value);
  }

  @override
  void updateConfig(TextInputConfiguration configuration) {
    _bridge.handleUpdateConfig(configuration);
  }
}
