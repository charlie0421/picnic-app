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
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';

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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );

    // Splash 화면의 기본 요소가 존재하는지 정도만 확인한다.
    expect(find.byType(MaterialApp), findsOneWidget);

    // 앱 시작이 구매 스트림 구독을 세운다. 예전에는 이 구독이 스토어 화면
    // initState 에서만 만들어졌고, 그래서 스토어가 없는 동안 도착한 결제
    // 이벤트는 broadcast 스트림에서 그냥 사라졌다 (앱이 결제 중 종료됐다가
    // 재실행된 경우, Ask to Buy 승인이 늦게 도착한 경우 등).
    expect(
      container.exists(globalPurchaseListenerProvider),
      isTrue,
      reason: '구매 이벤트 수신은 스토어 화면 진입이 아니라 앱 시작에 시작된다',
    );

    // 앱 시작 리컨사일(clearPendingPurchasesOnStartup → 1초 대기 →
    // processPendingTransactions 의 2초 타임아웃)이 끝날 시간을 준다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
