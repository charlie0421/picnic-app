import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';

import 'helpers/mock_supabase.dart';
import 'helpers/test_app.dart';

/// 실패한 오버플로가 (a) 위젯 결함인지 (b) 테스트 뷰포트(800x600) 아티팩트인지
/// 가르기 위한 임시 프로브.
void main() {
  setUp(initTestEnvironment);
  tearDown(tearDownMockSupabase);

  Future<String> renderAt(
    WidgetTester tester, {
    required Size surface,
    required Size designSize,
    required bool splitScreenMode,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildTestApp(
        const StorePointInfo(title: 'Default'),
        loggedIn: false,
        designSize: designSize,
        splitScreenMode: splitScreenMode,
      ),
    );
    await tester.pump();

    final errs = <String>[];
    for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
      final s = e.toString();
      if (s.contains('Unable to load asset')) continue;
      errs.add(s.split('\n').first);
    }
    return errs.isEmpty ? 'CLEAN' : errs.join(' | ');
  }

  testWidgets('StorePointInfo @ current test harness (800x600, design 375x812)',
      (tester) async {
    final r = await renderAt(tester,
        surface: const Size(800, 600),
        designSize: kLegacyTestDesignSize,
        splitScreenMode: false);
    // ignore: avoid_print
    print('OVERFLOW_PROBE[harness 800x600 / design 375x812] -> $r');
  });

  testWidgets('StorePointInfo @ production config (393x892, design 393x892)',
      (tester) async {
    final r = await renderAt(tester,
        surface: const Size(393, 892),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode);
    // ignore: avoid_print
    print('OVERFLOW_PROBE[prod 393x892 / design 393x892] -> $r');
  });

  testWidgets('StorePointInfo @ small phone (360x780, design 393x892)',
      (tester) async {
    final r = await renderAt(tester,
        surface: const Size(360, 780),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode);
    // ignore: avoid_print
    print('OVERFLOW_PROBE[small 360x780 / design 393x892] -> $r');
  });

  testWidgets('StorePointInfo @ test surface but production design',
      (tester) async {
    final r = await renderAt(tester,
        surface: const Size(800, 600),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode);
    // ignore: avoid_print
    print('OVERFLOW_PROBE[800x600 / design 393x892] -> $r');
  });
}
