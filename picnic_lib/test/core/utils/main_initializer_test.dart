import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';

void main() {
  group('MainInitializer', () {
    late Widget Function() mockAppBuilder;
    late FirebaseOptions mockFirebaseOptions;
    late Function() mockReflectableInitializer;
    late Future<bool> Function(Locale) mockLoadGeneratedTranslations;

    setUp(() {
      mockAppBuilder = () => const Text('Test App');
      mockFirebaseOptions = const FirebaseOptions(
        apiKey: 'test_api_key',
        appId: 'test_app_id',
        messagingSenderId: 'test_messaging_sender_id',
        projectId: 'test_project_id',
      );
      mockReflectableInitializer = () {};
      mockLoadGeneratedTranslations = (_) async => true;
    });

    test('initializeApp 메서드의 타입 확인', () {
      // initializeApp 메서드의 반환 타입 확인
      expect(
          MainInitializer.initializeApp(
            environment: 'test',
            firebaseOptions: mockFirebaseOptions,
            appBuilder: mockAppBuilder,
            loadGeneratedTranslations: mockLoadGeneratedTranslations,
            reflectableInitializer: mockReflectableInitializer,
          ),
          isA<Future<void>>());
    });

    test('initializeLanguageAsync 메서드의 타입 확인', () {
      // initializeLanguageAsync 메서드의 반환 타입 확인 (실제 호출은 못함)
      final future = MainInitializer.initializeLanguageAsync;
      expect(future, isA<Function>());
    });
  });
}
