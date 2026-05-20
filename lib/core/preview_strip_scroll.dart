import 'package:flutter/material.dart';

/// Scrolls a single-line preview [TextField] so the caret and last characters stay visible.
void schedulePreviewStripScroll({
  required ScrollController scrollController,
  required TextEditingController textController,
  required TextStyle textStyle,
  required bool Function() canScroll,
}) {
  void scroll() {
    if (!canScroll() || !scrollController.hasClients) return;

    final text = textController.text;
    final selection = textController.selection;
    if (!selection.isValid) return;

    final caretOffset = selection.extentOffset.clamp(0, text.length);
    final position = scrollController.position;

    // Typing at end: always show the last character and caret.
    if (caretOffset >= text.length) {
      final maxExtent = position.maxScrollExtent;
      if (position.pixels != maxExtent) {
        scrollController.jumpTo(maxExtent);
      }
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: text.substring(0, caretOffset),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);

    const edgeInset = 12.0;
    const caretWidth = 2.5;
    final caretX = painter.width + caretWidth;
    final viewport = position.viewportDimension;
    final pixels = position.pixels;

    if (caretX > pixels + viewport - edgeInset) {
      scrollController.jumpTo(
        (caretX - viewport + edgeInset).clamp(0.0, position.maxScrollExtent),
      );
    } else if (caretX < pixels + edgeInset) {
      scrollController.jumpTo(
        (caretX - edgeInset).clamp(0.0, position.maxScrollExtent),
      );
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    scroll();
    WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
  });
}
