import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';

void main() {
  group('LoggingObserver', () {
    late LoggingObserver observer;

    setUp(() {
      observer = LoggingObserver();
    });

    test('detectChanges does nothing for Impl types', () {
      // Should not throw
      observer.detectChanges(_ImplType(), _ImplType());
    });

    test('detectChanges does nothing for bool types', () {
      observer.detectChanges(true, false);
    });

    test('detectChanges does nothing for Locale types', () {
      observer.detectChanges(const Locale('ko'), const Locale('en'));
    });

    test('detectChanges prints in debug mode when objects differ', () {
      final messages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };

      observer.detectChanges(_TestObj(1), _TestObj(2));

      // Restore default
      debugPrint = debugPrintThrottled;

      if (kDebugMode) {
        expect(messages, isNotEmpty);
        expect(messages.first, contains('Object changed'));
      }
    });

    test('detectChanges does nothing when objects are same', () {
      final obj = _TestObj(1);
      final messages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };

      observer.detectChanges(obj, obj);

      debugPrint = debugPrintThrottled;

      // Same object should not print
      expect(messages, isEmpty);
    });
  });
}

class _ImplType {
  @override
  String toString() => 'SomeImpl';
}

class _TestObj {
  final int value;
  _TestObj(this.value);

  @override
  String toString() => 'TestObj($value)';
}
