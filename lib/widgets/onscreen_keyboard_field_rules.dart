import 'package:flutter/material.dart';

/// Optional keyboard rules for a focused [TextField] / [TextFormField] when using
/// [OnscreenKeyboardAttachment] (same knobs as [OnscreenTextField] on a host).
class OnscreenFieldRule {
  const OnscreenFieldRule({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.allowDecimalInput,
    this.integersOnly,
    this.maxFractionDigits,
    this.validator,
  });

  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final bool? allowDecimalInput;
  final bool? integersOnly;
  final int? maxFractionDigits;
  final String? Function(String)? validator;
}

/// Registers per-[FocusNode] rules read by [OnscreenKeyboardAttachment] when it
/// builds [CustomKeyboard] / [NumericKeyboard] for the active field.
abstract final class OnscreenKeyboardFieldRules {
  OnscreenKeyboardFieldRules._();

  static final Map<int, OnscreenFieldRule> _rules = {};

  static void register(FocusNode focusNode, OnscreenFieldRule rule) {
    _rules[focusNode.hashCode] = rule;
  }

  static void unregister(FocusNode focusNode) {
    _rules.remove(focusNode.hashCode);
  }

  static OnscreenFieldRule? lookup(FocusNode focusNode) =>
      _rules[focusNode.hashCode];
}
