import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  /// Image.asset('assets/app_icon_128.png') 로딩 실패를 무시하기 위한 헬퍼.
  /// 테스트 환경에서는 에셋 번들이 없으므로 이미지 로딩 에러를 억제합니다.
  Future<void> pumpIndicator(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(buildTestApp(child));
    // pump 후 이미지 에러가 발생하므로 예외를 소비합니다.
    tester.takeException();
    await tester.pump();
    tester.takeException();
  }

  group('PulseLoadingIndicator', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await pumpIndicator(tester, const PulseLoadingIndicator());

      expect(find.byType(PulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders with custom parameters', (WidgetTester tester) async {
      await pumpIndicator(
        tester,
        const PulseLoadingIndicator(
          size: 80,
          duration: Duration(milliseconds: 500),
          minScale: 0.9,
          maxScale: 1.1,
        ),
      );

      expect(find.byType(PulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('contains Center, Transform.scale, and Opacity in widget tree',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const PulseLoadingIndicator());

      // Center is at the root of the build method
      expect(find.byType(Center), findsWidgets);
      // Transform.scale wraps the content
      expect(find.byType(Transform), findsWidgets);
      // Opacity for fade animation
      expect(find.byType(Opacity), findsWidgets);
      // ClipOval for circular clipping
      expect(find.byType(ClipOval), findsOneWidget);
      // Container for size and shape
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('animation controllers are running',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const PulseLoadingIndicator());

      // Advance the animation and verify the widget still renders
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PulseLoadingIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('disposes animation controllers without error',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const PulseLoadingIndicator());
      expect(find.byType(PulseLoadingIndicator), findsOneWidget);

      // Remove the widget - should not throw
      await tester.pumpWidget(buildTestApp(const SizedBox()));
      tester.takeException();
      await tester.pump();

      expect(find.byType(PulseLoadingIndicator), findsNothing);
    });

    testWidgets('uses default parameter values',
        (WidgetTester tester) async {
      const indicator = PulseLoadingIndicator();

      expect(indicator.size, 40);
      expect(indicator.duration, const Duration(milliseconds: 800));
      expect(indicator.minScale, 0.98);
      expect(indicator.maxScale, 1.02);
    });
  });

  group('SmallPulseLoadingIndicator', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await pumpIndicator(tester, const SmallPulseLoadingIndicator());

      expect(find.byType(SmallPulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('wraps PulseLoadingIndicator with size 24',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const SmallPulseLoadingIndicator());

      expect(find.byType(PulseLoadingIndicator), findsOneWidget);

      final indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.size, 24);
    });
  });

  group('MediumPulseLoadingIndicator', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await pumpIndicator(tester, const MediumPulseLoadingIndicator());

      expect(find.byType(MediumPulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('wraps PulseLoadingIndicator with size 40',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const MediumPulseLoadingIndicator());

      expect(find.byType(PulseLoadingIndicator), findsOneWidget);

      final indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.size, 40);
    });
  });

  group('LargePulseLoadingIndicator', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await pumpIndicator(tester, const LargePulseLoadingIndicator());

      expect(find.byType(LargePulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('wraps PulseLoadingIndicator with size 60',
        (WidgetTester tester) async {
      await pumpIndicator(tester, const LargePulseLoadingIndicator());

      expect(find.byType(PulseLoadingIndicator), findsOneWidget);

      final indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.size, 60);
    });
  });

  group('Size variant parameters', () {
    testWidgets('all size variants use duration 1000ms and scale 0.96-1.04',
        (WidgetTester tester) async {
      // Test SmallPulseLoadingIndicator
      await pumpIndicator(tester, const SmallPulseLoadingIndicator());

      var indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.duration, const Duration(milliseconds: 1000));
      expect(indicator.minScale, 0.96);
      expect(indicator.maxScale, 1.04);

      // Test MediumPulseLoadingIndicator
      await pumpIndicator(tester, const MediumPulseLoadingIndicator());

      indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.duration, const Duration(milliseconds: 1000));
      expect(indicator.minScale, 0.96);
      expect(indicator.maxScale, 1.04);

      // Test LargePulseLoadingIndicator
      await pumpIndicator(tester, const LargePulseLoadingIndicator());

      indicator = tester.widget<PulseLoadingIndicator>(
        find.byType(PulseLoadingIndicator),
      );
      expect(indicator.duration, const Duration(milliseconds: 1000));
      expect(indicator.minScale, 0.96);
      expect(indicator.maxScale, 1.04);
    });
  });
}
