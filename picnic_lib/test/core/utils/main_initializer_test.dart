import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';

void main() {
  group('MainInitializer', () {
    late Widget Function() mockAppBuilder;

    setUp(() {
      mockAppBuilder = () => const Text('Test App');
    });

    test('initializeApp 메서드의 타입 확인', () async {
      // initializeApp 메서드의 반환 타입 확인
      final future = MainInitializer.initializeApp(
        environment: 'test',
        appBuilder: mockAppBuilder,
      );
      expect(future, isA<Future<void>>());
    });

    test('initializeLanguageAsync 메서드의 타입 확인', () {
      // initializeLanguageAsync 메서드의 반환 타입 확인 (실제 호출은 못함)
      final future = MainInitializer.initializeLanguageAsync;
      expect(future, isA<Function>());
    });
  });
}
