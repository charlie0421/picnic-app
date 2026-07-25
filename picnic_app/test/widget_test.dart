// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_lib/core/config/environment.dart';

void main() {
  setUpAll(() {
    Environment.initTestConfig({
      'theme': {
        'colors': {
          'primary': '0xFF6200EE',
          'secondary': '0xFF03DAC6',
          'sub': '0xFFBB86FC',
          'point': '0xFFFF0266',
          'point_900': '0xFFCF6679',
        },
      },
      'logging': {'level': 'off'},
    });
  });

  testWidgets('앱이 ProviderScope 안에서 빌드된다', (tester) async {
    // ProviderScope를 함께 Pump해서 Riverpod 의존성을 충족하고,
    // UI가 예외 없이 한 프레임이라도 그려지는지만 확인한다.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Splash 화면의 기본 요소가 존재하는지 정도만 확인한다.
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });
}
