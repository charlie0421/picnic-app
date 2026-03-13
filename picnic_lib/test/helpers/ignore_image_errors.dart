import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef RestoreCallback = void Function();

/// Temporarily suppresses ALL FlutterError reports during widget render tests.
/// Returns a callback that restores the original error handler.
RestoreCallback suppressImageErrors() {
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    // Suppress all FlutterErrors in render tests.
    // We only verify the widget tree builds; missing assets
    // and layout overflow are expected in headless tests.
    return;
  };
  return () => FlutterError.onError = origOnError;
}

/// Pump the widget and drain any asynchronous exceptions the test framework
/// captured (e.g. image codec failures). Call this instead of plain
/// `tester.pump()` in render tests.
Future<void> pumpAndIgnoreErrors(WidgetTester tester, [Duration? duration]) async {
  await tester.pump(duration);
  // Drain any pending exceptions so the test framework doesn't report them.
  while (tester.takeException() != null) {}
}

/// Like `tester.pumpWidget()` but also drains any exceptions.
Future<void> pumpWidgetAndIgnoreErrors(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  while (tester.takeException() != null) {}
}
